# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, '/dev/null'


# run this task only on servers with the :app role in Capistrano
# see Capistrano roles section below
every :day, :at => '4:30 am', :roles => [:app] do
  rake "mysql:dump"
end

every :reboot, :roles => [:app] do
  rake "util:start_delayed_job"
end

every :day, :at => '5:30 am', :roles => [:app] do
  rake "backup:rspec", :environment => "test"
end
