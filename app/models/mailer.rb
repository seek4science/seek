class Mailer < ActionMailer::Base

  def feedback user,topic,details,send_anonymously,base_host
    @anon = send_anonymously
    @anon = true if user.try(:person).nil?

    @details=details
    @topic=topic
    @person=user.try(:person)
    @host=base_host
    reply_to=user.person.email_with_name unless @anon
    mail(:from=>Seek::Config.noreply_sender,
         :to=>admin_emails,
         :subject=>"#{Seek::Config.application_name} Feedback provided - #{topic}",
         :reply_to=>reply_to)

  end

  def file_uploaded uploader,receiver,file,base_host
    @host=base_host
    @uploader=uploader.person
    @receiver=receiver
    @data_file=file
    mail(:from=>Seek::Config.noreply_sender,
         :to=>[uploader.person.email_with_name,receiver.email_with_name],
         :subject=>"#{Seek::Config.application_name} - File Upload",
         :reply_to=>uploader.person.email_with_name)
  end

  def request_publishing(publisher,owner,resources,base_host)
    @owner=owner
    @publisher=publisher
    @resources=resources
    @host=base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>owner.email_with_name,
         :reply_to=>publisher.email_with_name,
         :subject=>"A #{Seek::Config.application_name} member requests you make some items public")
  end

  def request_publish_approval(gatekeeper,user,resources,base_host)
    @gatekeeper = gatekeeper
    @requester=user.person
    @resources=resources
    @host=base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>gatekeeper.email_with_name,
         :reply_to=>user.person.email_with_name,
         :subject=>"A #{Seek::Config.application_name} member requested your approval to publish some items.")
  end

  def gatekeeper_approval_feedback requester, gatekeeper, items_and_comments, base_host
    @gatekeeper = gatekeeper
    @requester=requester
    @items_and_comments=items_and_comments
    @host=base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>requester.email_with_name,
         :subject=>"A #{Seek::Config.application_name} gatekeeper approved your publishing requests.")

  end

  def gatekeeper_reject_feedback requester, gatekeeper, items_and_comments, base_host
    @gatekeeper = gatekeeper
    @requester=requester
    @items_and_comments=items_and_comments
    @host=base_host

    mail(:from=>Seek::Config.noreply_sender,
         :to => requester.email_with_name,
         :subject => "A #{Seek::Config.application_name} gatekeeper rejected your publishing requests.",
         :reply_to => gatekeeper.email_with_name)
  end

  def request_resource(user,resource,details,base_host)
    @owners = resource.managers
    @requester=user.person
    @resource=resource
    @details=details
    @host=base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>resource.managers.collect{|m| m.email_with_name},
         :reply_to=>user.person.email_with_name,
         :subject=>"A #{Seek::Config.application_name} member requested a protected file: #{resource.title}")
  end

  def signup(user,base_host)
    @username=user.login
    @openid=user.openid
    @name=user.person.name
    @admins=admins
    @activation_code=user.activation_code
    @host=base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>user.person.email_with_name,
         :subject=>"#{Seek::Config.application_name} account activation")
  end

  def forgot_password(user,base_host)
    @username=user.login
    @name=user.person.name
    @reset_code=user.reset_password_code
    @host=base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>user.person.email_with_name,
         :subject=>"#{Seek::Config.application_name} - Password reset")
  end

  def welcome(user,base_host)
    @name = user.person.name
    @person = user.person
    @host = base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>user.person.email_with_name,
         :subject=>"Welcome to #{Seek::Config.application_name}")
  end
  
  def welcome_no_projects(user,base_host)
    @name = user.person.name
    @person = user.person
    @host = base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>user.person.email_with_name,
         :subject=>"Welcome to #{Seek::Config.application_name}")
  end

  def contact_admin_new_user(details,user,base_host)
    @details = details
    @person = user.person
    @user = user
    @host = base_host
    mail(:from=>Seek::Config.noreply_sender,
          :to=> admin_emails,
         :reply_to=>user.person.email_with_name,
         :subject=>"#{Seek::Config.application_name} member signed up")

  end

  def contact_project_manager_new_user(project_manager,details,user,base_host)

    @details = details
    @person = user.person
    @user = user
    @host = base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>project_manager_email(project_manager),
         :reply_to=>user.person.email_with_name,
         :subject=>"#{Seek::Config.application_name} member signed up, please assign this person to the #{I18n.t('project').pluralize.downcase} of which you are #{I18n.t('project').downcase} manager")
  end

  def resources_harvested(harvester_responses,user,base_host)
    @resources = harvester_resources
    @person = user.person
    @host = base_host
    subject_text = (harvester_responses.size > 1) ? 'New resources registered with SEEK' : 'New resource registered with SEEK'
    mail(:from=>Seek::Config.noreply_sender,
         :to=>user.person.email_with_name,
         :subject=>subject_text)
  end

  def announcement_notification(site_announcement, notifiee_info,base_host)
    #FIXME: this should really be part of the site_announcements plugin
    @site_announcement  = site_announcement
    @notifiee_info = notifiee_info
    @host = base_host
    mail(:from=>Seek::Config.noreply_sender,
         :to=>notifiee_info.notifiee.email_with_name,
         :subject=>"#{Seek::Config.application_name} Announcement: #{site_announcement.title}")
  end

  def test_email testing_email
    mail(:from=>Seek::Config.noreply_sender,
         :to=>testing_email,
         :subject=>"SEEK Configuration Email Test")
  end

  def notify_user_projects_assigned(person)
    @name = person.name
    @projects = person.projects

    mail(:from=>Seek::Config.noreply_sender,
         :to=>person.email_with_name,
         :subject=>"You have been assigned to a #{Seek::Config.application_name} project")
  end

  def report_run_problem(person, run)
    @person = person
    @run = run
    @error_outputs = run.outputs.select { |o| o.value_is_error? }

    attachments['taverna_server_log.txt'] = File.read(run.log.path) unless run.log.path.nil?
    attachments['portal_log.txt'] = run.failure_message unless run.failure_message.nil?

    mail(:from=>Seek::Config.noreply_sender,
         :to=>Seek::Config.support_email_address,
         :subject=>"#{Seek::Config.application_name} user has reported a problem with a workflow run")
  end

  private
  
  def admin_emails
    begin      
      admins.map { |p| p.email_with_name }
    rescue
      Rails.logger.error("Error determining admin email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end

  def project_manager_email project_manager
    begin
      project_manager.email_with_name
    rescue
      Rails.logger.error("Error determining #{I18n.t('project')} manager #{project_manager.name} email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end
  
  def admins
    Person.admins
  end

end
