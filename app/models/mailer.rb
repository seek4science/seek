class Mailer < ActionMailer::Base
  helper UsersHelper

  NOREPLY_SENDER="no-reply@sysmo-db.org"

  def admin_emails
    begin      
      User.admins.map { |a| a.person.email_with_name }
    rescue
      @@logger.error("Error determining admin email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end

  def request_resource(user,resource,base_host)

    subject "A Sysmo Member requested a protected file: #{resource.title}"
    recipients resource.contributor.person.email_with_name
    from NOREPLY_SENDER
    reply_to user.person.email_with_name
    sent_on Time.now
    
    body :owner=>resource.contributor.person,:requester=>user.person,:resource=>resource,:host=>base_host
  end

  def signup(user,base_host)
    subject     'Sysmo SEEK account activation'
    recipients  user.person.email_with_name
    from        NOREPLY_SENDER
    sent_on     Time.now

    body        :username=>user.login, :name=>user.person.name, :admins=>User.admins.collect{|u| u.person}, :activation_code=>user.activation_code, :host=>base_host
  end

  def forgot_password(user,base_host)
    subject    'Sysmo SEEK - Password reset'
    recipients user.person.email_with_name
    from       NOREPLY_SENDER
    sent_on    Time.now
    
    body       :username=>user.login, :name=>user.person.name, :reset_code => user.reset_password_code, :host=>base_host
  end

  def welcome(user,base_host)
    subject    'Welcome to Sysmo SEEK'
    recipients user.person.email_with_name
    from       NOREPLY_SENDER
    sent_on    Time.now
    
    body       :name=>user.person.name,:person=>user.person, :host=>base_host
  end

  def contact_admin_new_user_no_profile(details,user,base_host)
    
    subject    'Sysmo Member signed up'
    recipients admin_emails
    from       NOREPLY_SENDER
    sent_on    Time.now
    
    body       :details=>details, :person=>user.person, :user=>user, :host=>base_host
  end

end
