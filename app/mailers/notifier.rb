class Notifier < ActionMailer::Base
  def ask_a_question question
    @question = question

    # TODO: this process needs to be moved to a helper method
    # it's repeated in each action with slightly different information
    email = Rails.env == 'production' ? ADMIN_MAIL_TO : DEFAULT_MAIL_TO
    subject = Rails.env == 'production' ? 'New Question from SPARC' : "[#{Rails.env.capitalize} - EMAIL TO #{ADMIN_MAIL_TO}] New Question from SPARC"

    mail(:to => email, :from => @question.from, :subject => subject)
  end

  def new_identity_waiting_for_approval identity
    @identity = identity
    
    email = Rails.env == 'production' ? ADMIN_MAIL_TO : DEFAULT_MAIL_TO
    subject = Rails.env == 'production' ? 'New Question from SPARC' : "[#{Rails.env.capitalize} - EMAIL TO #{ADMIN_MAIL_TO}] Request for new SPARC account submitted and awaiting approval"
    
    mail(:to => email, :from => @identity.email, :subject => subject) 
  end

  def notify_user project_role, service_request, xls, approval
    @identity = project_role.identity
    @role = project_role.role 

    @approval_link = nil
    if approval and project_role.project_rights == 'approve'
      @approval_link = approve_changes_service_request_url(service_request, :approval_id => approval.id)
    end
    
    @protocol = service_request.protocol
    @service_request = service_request
    @portal_link = USER_PORTAL_LINK + "?default_protocol=#{@protocol.id}"
    @portal_text = "To VIEW and/or MAKE any changes to this request, please click here."
    
    attachments["service_request_#{@service_request.id}.xls"] = xls 
    
    # only send these to the correct person in the production env
    email = Rails.env == 'production' ? @identity.email : DEFAULT_MAIL_TO
    subject = Rails.env == 'production' ? "SPARC Service Request" : "[#{Rails.env.capitalize} - EMAIL TO #{@identity.email}] SPARC Service Request"
    
    mail(:to => email, :from => "no-reply@musc.edu", :subject => subject)
  end

  def notify_admin service_request, submission_email_address, xls
    @protocol = service_request.protocol
    @service_request = service_request
    @role == 'none'
    @approval_link = nil

    @portal_link = USER_PORTAL_LINK + "admin"
    @portal_text = "Administrators/Service Providers, Click Here"
    
    attachments["service_request_#{@service_request.id}.xls"] = xls 
    
    # only send these to the correct person in the production env
    email = Rails.env == 'production' ?  submission_email_address : DEFAULT_MAIL_TO
    subject = Rails.env == 'production' ? "SPARC Service Request" : "[#{Rails.env.capitalize} - EMAIL TO #{submission_email_address}] SPARC Service Request"
    
    mail(:to => email, :from => "no-reply@musc.edu", :subject => subject)
  end
  
  def notify_service_provider service_provider, service_request, attachments_to_add
    @protocol = service_request.protocol
    @service_request = service_request
    @role == 'none'
    @approval_link = nil

    @portal_link = USER_PORTAL_LINK + "admin"
    @portal_text = "Administrators/Service Providers, Click Here"
    
    attachments_to_add.each do |file_name, document|
      attachments[file_name] = document
    end
    
    # only send these to the correct person in the production env
    email = Rails.env == 'production' ? service_provider.identity.email : DEFAULT_MAIL_TO
    subject = Rails.env == 'production' ? "SPARC Service Request" : "[#{Rails.env.capitalize} - EMAIL TO #{service_provider.identity.email}] SPARC Service Request"
    
    mail(:to => email, :from => "no-reply@musc.edu", :subject => subject)
  end

  def account_status_change identity, approved
    @approved = approved
    
    email_from = Rails.env == 'production' ? ADMIN_MAIL_TO : DEFAULT_MAIL_TO
    email_to = Rails.env == 'production' ? identity.email : DEFAULT_MAIL_TO
    subject = Rails.env == 'production' ? "SPARC account request - status change" : "[#{Rails.env.capitalize} - EMAIL TO #{identity.email}] SPARC account request - status change"

    mail(:to => email_to, :from => email_from, :subject => subject)
  end

  def obtain_research_pricing service_provider, service_request

  end
end
