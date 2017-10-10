require 'yaml'
require 'erb'
require 'ostruct'

namespace :setup do
  desc 'create configuration files from template'
  task :create_configuration do
    template = File.read(File.expand_path('../../config/application.yml.erb', File.dirname(__FILE__)))
    STDOUT.puts "enter rails_env: "
    STDOUT.puts "enter default_mail_to: "
    STDOUT.puts "enter admin_mail_to: "
    content = ERB.new(template).result(binding)
    File.open(File.expand_path('../../config/application.yml.generated', File.dirname(__FILE__)), "w") { |f| f.write content }
  end

  desc 'create configuration from config.yml'
  task :create_from_config do
    STDOUT.puts "enter rails_env: "
    rails_env = STDIN.gets.strip
    template = File.read(File.expand_path('../../config/application.yml.erb', File.dirname(__FILE__)))
    config = YAML::load(File.expand_path('../../config/config.yml', File.dirname(__FILE__)))[rails_env]
    opts = OpenStruct.new(config)
    content = ERB.new(template).result(opts.instance_eval {binding})
    File.open(File.expand_path('../../config/application.yml.generated', File.dirname(__FILE__)), "w") { |f| f.write content }
  end
end
