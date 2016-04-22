require 'colorize'
namespace :db do
  desc "Truncate all existing data"
  task :truncate, [:table_name] => :environment do |t, args|
    def prompt(*args)
      print(*args)
      STDIN.gets.strip
    end

    def truncate_all
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
      end
    end

    config = ActiveRecord::Base.configurations[::Rails.env]
    ActiveRecord::Base.establish_connection
    case config["adapter"]
    when "mysql", "postgresql", 'mysql2'
      if args[:table_name]
        puts "TRUNCATE #{args[:table_name]}".red
        ActiveRecord::Base.connection.execute("TRUNCATE #{args[:table_name]}")
      else
        puts "truncate all tables. All data will be lost."
        truncate_all
      end
    when "sqlite", "sqlite3"
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
        ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='#{table}'")
      end
     ActiveRecord::Base.connection.execute("VACUUM")
    end
  end
end
