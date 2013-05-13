class Mailer < ActionMailer::Base

  default :from=>Seek::Config.noreply_sender

  def feedback user,topic,details,send_anonymously,base_host
    send_anonymously = true unless user.try(:person)
    subject "#{Seek::Config.application_name} Feedback provided - #{topic}"
    recipients admin_emails
    from Seek::Config.noreply_sender
    reply_to user.person.email_with_name unless  send_anonymously
    sent_on Time.now

    body :topic=>topic,:details=>details,:anon=>send_anonymously,:host=>base_host,:person=>user.try(:person)
  end

  def file_uploaded uploader,receiver,file,base_host
    subject "#{Seek::Config.application_name} - File Upload"
    recipients [uploader.person.email_with_name,receiver.email_with_name]
    from     Seek::Config.noreply_sender
    reply_to uploader.person.email_with_name
    sent_on Time.now

    body :host=>base_host,:uploader=>uploader.person, :receiver => receiver,:data_file => file
  end

  def request_publishing(publisher,owner,resources,base_host)

    subject "A #{Seek::Config.application_name} member requests you make some items public"
    recipients owner.email_with_name
    from       Seek::Config.noreply_sender
    reply_to   publisher.email_with_name
    sent_on Time.now

    body :host=>base_host,:owner=>owner, :publisher=>publisher,:resources=>resources
  end

  def request_publish_approval(gatekeepers,user,resource,base_host)

      subject "A #{Seek::Config.application_name} member requested your approval to publish: #{resource.title}"
      recipients gatekeepers.collect{|m| m.email_with_name}
      from Seek::Config.noreply_sender
      reply_to user.person.email_with_name
      sent_on Time.now

      body :gatekeepers=>gatekeepers,:requester=>user.person,:resource=>resource,:host=>base_host
  end

  def gatekeeper_approval_feedback requester, gatekeeper, resource, base_host

    subject "A #{Seek::Config.application_name} gatekeeper approved your request to publish: #{resource.title}"
    recipients requester.email_with_name
    from Seek::Config.noreply_sender
    sent_on Time.now

    body :gatekeeper=>gatekeeper,:requester=>requester,:resource=>resource,:host=>base_host
  end

  def gatekeeper_reject_feedback requester, gatekeeper, resource, extra_comment, base_host

  subject "A #{Seek::Config.application_name} gatekeeper rejected your request to publish: #{resource.title}"
    recipients requester.email_with_name
    from Seek::Config.noreply_sender
    reply_to gatekeeper.email_with_name
    sent_on Time.now

    if extra_comment.blank?
      extra_comment = gatekeeper.name + " did not leave any reasons/comments"
    else
      extra_comment = gatekeeper.name + " left reasons/comments: " + extra_comment
    end
    body :gatekeeper=>gatekeeper,:requester=>requester,:resource=>resource,:extra_comment=>extra_comment,:host=>base_host
  end

  def request_resource(user,resource,details,base_host)

    subject "A #{Seek::Config.application_name} member requested a protected file: #{resource.title}"
    recipients resource.managers.collect{|m| m.email_with_name}
    from Seek::Config.noreply_sender
    reply_to user.person.email_with_name
    sent_on Time.now
    
    body :owners=>resource.managers,:requester=>user.person,:resource=>resource,:details=>details,:host=>base_host
  end

  def signup(user,base_host)
    @username=user.login
    @openid=user.openid
    @name=user.person.name
    @admins=admins
    @activation_code=user.activation_code
    @host=base_host
    mail(:to=>user.person.email_with_name,:subject=>"#{Seek::Config.application_name} account activation")
  end

  def forgot_password(user,base_host)
    @username=user.login
    @name=user.person.name
    @reset_code=user.reset_password_code
    @host=base_host
    mail(:to=>user.person.email_with_name, :subject=>"#{Seek::Config.application_name} - Password reset")
  end

  def welcome(user,base_host)
    subject    "Welcome to #{Seek::Config.application_name}"
    recipients user.person.email_with_name
    from       Seek::Config.noreply_sender
    sent_on    Time.now
    
    body       :name=>user.person.name,:person=>user.person, :host=>base_host
  end
  
  def welcome_no_projects(user,base_host)
    subject    "Welcome to #{Seek::Config.application_name}"
    recipients user.person.email_with_name
    from       Seek::Config.noreply_sender
    sent_on    Time.now
    
    body       :name=>user.person.name,:person=>user.person, :host=>base_host
  end

  def contact_admin_new_user_no_profile(details,user,base_host)

    subject    "#{Seek::Config.application_name} member signed up"
    recipients admin_emails
    from       Seek::Config.noreply_sender
    reply_to   user.person.email_with_name
    sent_on    Time.now

    body       :details=>details, :person=>user.person, :user=>user, :host=>base_host
  end

  def contact_project_manager_new_user_no_profile(project_manager,details,user,base_host)
    subject    "#{Seek::Config.application_name} member signed up, please assign this person to the projects which you are project manager"
    recipients project_manager_email(project_manager)
    from       Seek::Config.noreply_sender
    reply_to   user.person.email_with_name
    sent_on    Time.now

    body       :details=>details, :person=>user.person, :user=>user, :host=>base_host
  end

  def resources_harvested(harvester_responses,user,base_host)
    subject_text = (harvester_responses.size > 1) ? 'New resources registered with SEEK' : 'New resource registered with SEEK'
    subject    subject_text
    recipients user.person.email_with_name
    from       Seek::Config.noreply_sender
    sent_on    Time.now
    
    body       :resources => harvester_responses, :person=>user.person, :host=>base_host
  end
  
  def announcement_notification(site_announcement, notifiee_info,base_host)
    subject "#{Seek::Config.application_name} Announcement: #{site_announcement.title}"
    recipients notifiee_info.notifiee.email_with_name    
    from       Seek::Config.noreply_sender
    sent_on    Time.now
    
    sent_on Time.now

    body :site_announcement=>site_announcement, :notifiee_info=>notifiee_info,:host=>base_host
  end

  def test_email testing_email
    subject "Test email"
    recipients testing_email
    from Seek::Config.noreply_sender
    sent_on Time.now
    body
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
      Rails.logger.error("Error determining project manager #{project_manager.name} email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end
  
  def admins
    Person.admins
  end

end
