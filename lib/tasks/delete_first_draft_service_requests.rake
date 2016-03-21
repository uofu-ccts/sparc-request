desc 'Delete any service request in first draft status more than a week old'
task delete_first_draft_service_requests: :environment do

  def prompt(*args)
    print(*args)
    STDIN.gets.strip
  end

  one_week_ago = Time.now - 7.days
  requests = ServiceRequest.where("status = ? AND created_at < ?", 'first_draft', one_week_ago)

  continue = prompt("Preparing to delete #{requests.count} service requests, do you wish to continue? (Yes/No) ")

  if continue == 'Yes'
    requests.each do |request|
      request.without_auditing do
        puts "Deleting service request with an id of #{request.id}, status: #{request.status}..."
        request.destroy
      end
    end
  else
    puts "Exiting task..."
  end
end