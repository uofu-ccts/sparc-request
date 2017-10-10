require 'net/ldap' # gem install net-ldap

namespace :util do
  desc 'search ldap'
  task :search_ldap => :environment do
    def prompt(*args)
      print(*args)
      STDIN.gets.strip
    end

    begin
      term = prompt 'enter search term: '
      identity = Directory.search(term.strip)
      identity.each do |user|
        puts "-" * 20
        puts user.inspect
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end
  end


end
