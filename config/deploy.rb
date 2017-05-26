# lock '3.4.0'

set :rvm_ruby_version, '2.1.5'

set :application, 'sparc-request'
set :repo_url, 'https://github.com/uofu-ccts/sparc-request.git'

# Default branch is :master
# set :branch, "development"
set :branch, ENV['branch'] || ask('Branch: ', nil)

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/vagrant/sparc-request'

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :pty is false
set :pty, true

set :days_to_keep_backups, 30

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/application.yml', 'config/database.yml', 'config/epic.yml', 'config/ldap.yml', 'config/cas.yml', 'config/secrets.yml', '.env')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :rails_env, fetch(:stage)

# use copy will clone the repo and then upload the entire app to target server
# set :deploy_via, :copy
# use remote_cache require set up  ssh agent forwarding or copy private key to target server, but only update what is changed
set :deploy_via, :remote_cache

# set the locations that we will look for changed assets to determine whether to precompile
set :assets_dependencies, %w(app/assets lib/assets vendor/assets Gemfile config/routes.rb themes/assets)

# to namespace the crontab entries by application and stage
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

class PrecompileRequired < StandardError; end

require 'colorize'

def confirm
  set :confirm, ask('Confirm? (yes/no):', 'no')
end
def is_confirmed
  fetch(:confirm).downcase == 'yes' || fetch(:confirm).downcase == 'y'
end

def ask_times
  set :times, ask('How many times? (a number):', nil)
  fetch(:times)
end

def ask_name(type)
  set :name, ask("What is the name of #{type}? (a string):", nil)
  fetch(:name)
end

namespace :deploy do
  # FYI: this is not run by default.
  # Capistrano 3 no longer runs that task by default as many app servers don't require it. Add this to your config/deploy.rb:
  # after 'deploy:publishing', 'deploy:restart'
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      execute "touch #{current_path}/tmp/restart.txt"
    end
  end

  desc 'restart passenger process'
  task :restart_passenger do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec script/delayed_job restart"
        end
        execute :chmod, '777', 'tmp'
        execute :touch, 'tmp/restart.txt'
      end
    end
  end

  after :finishing, :restart_passenger

  namespace :assets do
    desc 'Precompile assets locally and upload to server'
    task :precompile_locally_copy do
      on roles(:app) do
        run_locally do
          with rails_env: fetch(:rails_env) do
            execute 'rake assets:precompile'
          end
        end

        execute "cd #{release_path} && mkdir public" rescue nil
        execute "cd #{release_path} && mkdir public/assets" rescue nil
        execute 'rm -rf public/assets/*'

        upload! 'public/assets', "#{release_path}/public", recursive: true

      end
    end

    desc 'Upload themes'
    task :upload_themes do
      on roles(:app) do
        execute "rm -rf #{shared_path}/themes"
        upload! 'themes', "#{shared_path}/", recursive: true
      end
    end

    desc 'Run the precompile task locally and upload to server'
    task :precompile_locally_archive do
      on roles(:app) do
        run_locally do
          execute 'rm tmp/assets.tar.gz' rescue nil
          execute 'rm -rf public/assets/*'

          with rails_env: fetch(:rails_env) do
            execute 'rake assets:precompile'
          end

          execute 'touch assets.tar.gz && rm assets.tar.gz'
          execute 'tar zcvf assets.tar.gz public/assets/'
          execute 'mv assets.tar.gz tmp/'
        end

        # Upload precompiled assets
        execute 'rm -rf public/assets/*'
        upload! "tmp/assets.tar.gz", "#{release_path}/assets.tar.gz"
        execute "cd #{release_path} && tar zxvf assets.tar.gz && rm assets.tar.gz"
      end
    end

    desc "Precompile assets if changed"
    task :precompile_changed do
      on roles(:app) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            begin

              # find the most recent release
              latest_release = capture(:ls, '-xr', releases_path).split[1]

              # precompile if this is the first deploy
              raise PrecompileRequired unless latest_release

              #
              latest_release_path = releases_path.join(latest_release)

              # precompile if the previous deploy failed to finish precompiling
              execute(:ls, latest_release_path.join('assets_manifest_backup')) rescue raise(PrecompileRequired)

              fetch(:assets_dependencies).each do |dep|
                #execute(:du, '-b', release_path.join(dep)) rescue raise(PrecompileRequired)
                #execute(:du, '-b', latest_release_path.join(dep)) rescue raise(PrecompileRequired)

                # execute raises if there is a diff
                execute(:diff, '-Naur', release_path.join(dep), latest_release_path.join(dep)) rescue raise(PrecompileRequired)
              end

              warn("-----Skipping asset precompile, no asset diff found")

              # copy over all of the assets from the last release
              execute(:cp, '-rf', latest_release_path.join('public', fetch(:assets_prefix)), release_path.join('public', fetch(:assets_prefix)))

            rescue PrecompileRequired
              warn("----Run assets precompile")

              execute(:rake, "assets:precompile")
            end
          end
        end
      end
    end
  end

end

namespace :mysql do


  desc "performs a backup (using mysqldump) in app shared dir"
  task :backup do
    if ENV['perform_db_backups']
      on roles(:app) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            filename = "#{fetch(:application)}.db_backup.#{Time.now.strftime("%Y-%m-%d-%H%M%S")}.sql.gz"
            filepath = "#{shared_path}/database_backups/#{filename}"
            execute "mkdir -p #{shared_path}/database_backups"
            execute :bundle, "exec rake mysql:dump[#{filepath}]"
          end
        end
      end

    else
      puts "    *************************"
      puts "    Skipping Database Backups"
      puts "    *************************"
    end
  end

  desc "removes all database backups that are older than days_to_keep_backups"
  task :cleanup_backups do
    if ENV['perform_db_backups']
      on roles(:app) do
        within current_path do
          with rails_env: fetch(:rails_env) do

            backup_dir = "#{shared_path}/database_backups"
            # Gets the output of ls as a string and splits on new lines and
            # selects the bziped files.
            backups = capture("ls #{backup_dir}").split("\n").find_all {|file_name| file_name =~ /.*\.gz/}
            old_backup_date = (Time.now.to_date - days_to_keep_backups).to_time
            backups.each do |file_name|
              # Gets the float epoch timestamp out of the file name
              timestamp = file_name.match(/((\d{4})-(\d{2})-(\d{2})-(\d{6}))/)[1]
              backup_time = Time.parse(timestamp)
              if backup_time < old_backup_date
                run "rm #{backup_dir}/#{file_name}"
              end
            end

          end
        end
      end

    else
      puts "    *************************"
      puts "    Skipping Database Backups Cleanup"
      puts "    *************************"
    end
  end


  desc 'truncate all tables, but doesn\'t touch migrations'
  task :truncate do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec rake mysql:truncate --trace"
        end
      end
    end
  end

  desc 'Dump the production database to db/production_data.sql'
  task :dump do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec rake mysql:dump --trace"
          download! "#{current_path}/tmp/#{fetch(:rails_env)}_data.sql.gz", "tmp/#{fetch(:rails_env)}_data.sql.gz"
        end
      end
    end
  end

  desc 'Upload mysql statements and import them'
  task :upload_and_import do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          upload! StringIO.new(File.read("tmp/#{fetch(:rails_env)}_data.sql.gz")), "#{current_path}/tmp/production_data.sql.gz"
          execute "gzip -d -f #{current_path}/tmp/production_data.sql.gz"
          execute :bundle, "exec rake mysql:load_from_production_dump --trace"
        end
      end
    end
  end

  desc 'Downloads db/production_data.sql from production server to local'
  task :download_dump do
    on roles(:db) do
      download! "#{current_path}/tmp/production_data.sql.gz", "tmp/production_data.sql.gz"
    end
  end

  desc 'Cleans up dump data file'
  task :cleanup_dump do
    on roles(:db) do
      execute "rm #{current_path}/tmp/production_data.sql.gz"
    end
  end

  desc 'Dump, download and clean up'
  task :db_runner do
    on roles(:db) do
      invoke 'mysql:dump'
      invoke 'mysql:download_dump'
      invoke 'mysql:cleanup_dump'
    end
  end

end

namespace :setup do

  desc "backup all configuration fiels"
  task :backup_config do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec rake backup:config"
          download! "#{current_path}/tmp/config_yml.zip", "tmp/#{fetch(:rails_env)}_config_yml.zip"
        end
      end
    end
  end

  desc "Upload database.yml file."
  task :upload_yml do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      upload! StringIO.new(File.read("config/application.yml")), "#{shared_path}/config/application.yml"
      upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/database.yml"
      upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/epic.yml"
      upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/ldap.yml"
      upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/cas.yml"
    end
  end

  desc "Seed the database."
  task :seed_db do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "install"
          execute :rake, "db:create"
          execute :rake, "db:migrate"
          execute :rake, "db:seed"
        end
      end
    end
  end

  desc "Seed the database."
  task :catalog do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec rake db:seed:catalog_manager"
        end
      end
    end
  end

  desc "batch create identity"
  task :batch_create_identity do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          times = ask_times
          execute :bundle, "exec rake demo:batch_create_identity[#{times}]" # times is a number and contains no empty space, no need to add single quote around it
        end
      end
    end
  end

  desc "fix processing ssrs"
  task :fix_processing_ssrs do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec rake demo:fix_processing_ssrs"
        end
      end
    end
  end

  desc "batch create service"
  task :batch_create_service do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          name = ask_name('Core')
          ldap_uid = ask_name('ldap_uid')
          times = ask_times
          execute :bundle, "exec rake demo:batch_create_service[#{ldap_uid},'#{name}',#{times}]" # name is a string which could contain empty spaces, use single quote to wrap it
        end
      end
    end
  end

  desc "batch create project"
  task :batch_create_project do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          ldap_uid = ask_name('ldap_uid')
          times = ask_times
          execute :bundle, "exec rake demo:batch_create_project[#{ldap_uid},#{times}]" # ldap_uid has no empty spaces, so no need to wrap it with single quote
        end
      end
    end
  end

  desc "truncate tables."
  task :truncate do

    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          set :all, ask('Truncate all? (yes/no):', 'no')
          if fetch(:all).downcase == 'yes' || fetch(:all).downcase == 'y'
            puts "truncate all table. all data will be lost. please confirm".red
            confirm
            if is_confirmed
              execute :bundle, "exec rake db:truncate"
            end

          else
            set :table_name, ask('Enter the table to truncate:', nil)
            table_name = fetch(:table_name).strip
            if !table_name.empty?
              puts "exec rake db:truncate['#{table_name}']. please confirm".red
              confirm
              if is_confirmed
                execute :bundle, "exec rake db:truncate['#{table_name}']"
              end

            end
          end
        end
      end
    end
  end

  desc 'import catalogs and services'
  task :import_catalog do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: fetch(:rails_env) do
          set :catalog_manager, ask('Enter the username as the catalog manager:', nil)
          ldap_uid = fetch(:catalog_manager).strip
          if !ldap_uid.empty?
            execute :bundle, "exec rake data:import_institution_and_service['#{ldap_uid}']"
          end
        end
      end
    end
  end

  desc "Symlinks config files for Nginx and Unicorn."
  task :symlink_vhost do
    on roles(:root) do
      require 'erb'
      template = File.read("config/apache.conf.erb")
      content = ERB.new(template).result(binding)
      path = "config/apache.conf"
      File.open(path, "w") { |f| f.write content }
      upload! StringIO.new(File.read("#{path}")), "#{shared_path}/#{path}"
      sudo "ln -nfs #{shared_path}/#{path} /etc/httpd/sites-enabled/#{fetch(:application)}.conf"
   end
  end

  desc "restart apache httpd service"
  task :restart_httpd do
    on roles(:root) do
      sudo "service httpd restart"
    end
  end

end


namespace :survey do
  desc "load/update a survey"
  task :parse do
    if ENV['FILE']
      transaction do
        run "cd #{current_path} && rake surveyor FILE=#{ENV['FILE']} RAILS_ENV=#{rails_env}"
      end
    else
      raise "FILE must be specified (eg. cap survey:parse FILE=surveys/your_survey.rb)"
    end
  end
end

before "deploy", 'mysql:backup'
