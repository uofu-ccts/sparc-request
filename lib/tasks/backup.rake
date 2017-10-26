require 'zip'
require 'colorize'
require 'yaml'
require 'hashdiff'

namespace :backup do

  desc "run rspec"
  task :rspec => :environment do
    system('bundle exec rake assets:clobber')
    `RUBYOPT=W0 bundle exec rspec --color --format documentation --out tmp/#{Time.now.strftime("%Y-%m-%d-%H%M%S")}-test-results`
  end

  desc "sort application.yml"
  task :sort_yml, [:file_path] => :environment do |t, args|
    file_path = args[:file_path] ? args[:file_path] : File.join('config', "application.yml")
    application_config = YAML.load_file(file_path)[Rails.env]
    result_hash = Hash.new
    result_hash[Rails.env.to_s] = Hash[application_config.sort]
    File.open(Rails.root.join('config', 'application.yml.sorted'), 'w') { |file| file.write result_hash.to_yaml }
  end

  desc 'compare two yaml files'
  task :compare_yml, [:file1, :file2, :enva, :envb] => :environment do |t, args|
    filea = args[:file1]
    fileb = args[:file2]
    enva = args[:enva] || Rails.env
    envb = args[:envb] || Rails.env
    filea_config = YAML.load_file(filea)[enva]
    fileb_config = YAML.load_file(fileb)[envb]
    puts HashDiff.diff(filea_config, fileb_config)
  end

  desc "backup all config yml files"
  task :config => :environment do
    zipfile_path = Rails.root.join('tmp', 'config_yml.zip')

    File.unlink(zipfile_path) unless !File.exists?(zipfile_path)

    Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
      Dir[Rails.root.join('config', '*.yml')].each do |f|
        #Make a one line info
        puts "#{f}: #{File.size(f)/1024}KB".green
        zipfile.add(File.basename(f), File.realpath(f))
      end
    end


  end
end
