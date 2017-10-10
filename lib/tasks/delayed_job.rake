namespace :util do
  desc 'start delayed job'
  task :start_delayed_job => :environment do
    `bundle exec script/delayed_job start`
  end


end
