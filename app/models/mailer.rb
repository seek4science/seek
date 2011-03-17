class Mailer < ActionMailer::Base
  helper UsersHelper  

  def feedback user,topic,details,send_anonymously,base_host
    subject "#{Seek::Config.application_name} Feedback provided - #{topic}"
    recipients admin_emails
    from Seek::Config.noreply_sender
    reply_to user.person.email_with_name unless send_anonymously
    sent_on Time.now

    body :topic=>topic,:details=>details,:anon=>send_anonymously,:host=>base_host,:person=>user.person
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
    subject     "#{Seek::Config.application_name} account activation"
    recipients  user.person.email_with_name
    from        Seek::Config.noreply_sender
    sent_on     Time.now

    body        :username=>user.login,:openid=>user.openid, :name=>user.person.name, :admins=>admins, :activation_code=>user.activation_code, :host=>base_host
  end

  def forgot_password(user,base_host)
    subject    "#{Seek::Config.application_name} - Password reset"
    recipients user.person.email_with_name
    from       Seek::Config.noreply_sender
    sent_on    Time.now
    
    body       :username=>user.login, :name=>user.person.name, :reset_code => user.reset_password_code, :host=>base_host
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

  private
  
  def admin_emails
    begin      
      admins.map { |p| p.email_with_name }
    rescue
      @@logger.error("Error determining admin email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end
  
  def admins
    Person.admins
  end

end
