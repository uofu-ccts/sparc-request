namespace :db do
  desc "Truncate all existing data"
  task :truncate => :environment do
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
      all = prompt 'truncate all tables? (yes/no)'
      if all.downcase == 'yes' || all.downcase == 'y'
        truncate_all
      end
      table_name = prompt 'truncate one table. enter the table name:'
      ActiveRecord::Base.connection.execute("TRUNCATE #{table_name}")
    when "sqlite", "sqlite3"
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
        ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='#{table}'")
      end
     ActiveRecord::Base.connection.execute("VACUUM")
    end
  end
end
