require 'zip'
require 'colorize'

namespace :backup do
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
