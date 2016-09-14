# Based on http://errtheblog.com/posts/31-rake-around-the-rosie
require 'yaml'

namespace :mysql do

  desc "Truncate all tables, but keep migrations"
  task :truncate => :environment do
    conn = ActiveRecord::Base.connection
    tables = conn.execute("show tables").map { |r| r[0] }
    tables.delete "schema_migrations"
    tables.each { |t| conn.execute("TRUNCATE #{t}") }
  end

  desc "Launch mysql shell."
  task :console do
    puts sh_mysql(database_config)
    system sh_mysql(database_config)
  end

  desc "Dump the current database to a gzipped MySQL file"
  task :dump => :environment do
    file_path = File.join('tmp', "#{ENV['RAILS_ENV']}_data.sql.gz")
    `#{sh_mysqldump(database_config)} | gzip > #{file_path}`
  end

  desc "Refreshes your local development environment to the current production database"
  task :refresh_from_production do
    `cap mysql:db_runner`
    Rake::Task['mysql:unzip_production_dump'].invoke
    Rake::Task['mysql:load_from_production_dump'].invoke
  end

  desc "Unzips production data downloaded to your tmp directory"
  task :unzip_production_dump do
    puts 'Unzipping from production dump'
    `gunzip tmp/production_data.sql.gz`
  end

  desc "Loads the production data downloaded into tmp/production_data.sql into your local development database"
  task :load_from_production_dump do
    puts 'Loading from production dump'
    puts "#{sh_mysql(database_config)} < tmp/production_data.sql"
    `#{sh_mysql(database_config)} < tmp/production_data.sql`
    puts 'Loaded from production dump'
  end

  def require_environment(env)
    unless ENV['RAILS_ENV'] == env
      raise "Can only run this in dev environment"
    end
  end

  def database_config
    config = YAML.load(open(File.join('config', 'database.yml')))[ENV['RAILS_ENV']]
    unless config["adapter"] == 'mysql2'
      raise "Task not supported by '#{config["adapter"]}'"
    end
    config
  end

  def connection_options(config)
    options = ''
    options << " -u #{config['username']}" if config['username']
    # http://stackoverflow.com/questions/15783701/which-characters-need-to-be-escaped-in-bash-how-do-we-know-it
    if config['password']
      escaped = config['password'].chars.to_a.map { |c| "\\" + c } .join('')
      options << " -p#{escaped}"
    end
    options << " -h #{config['host']}"     if config['host']
    options << " -P #{config['port']}"     if config['port']
    options << " #{config['database']}"    if config['database']
  end

  def sh_mysql(config)
    "mysql#{connection_options(config)}"
  end

  def sh_mysqldump(config)
    "mysqldump#{connection_options(config)}"
  end

end
