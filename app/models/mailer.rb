class Mailer < ActionMailer::Base
  helper UsersHelper

  def admin_emails
    begin
      admins=User.find(:all,:conditions=>{:is_admin=>true}, :include=>:person)
      admins.map { |a| a.person.email_with_name }
    rescue
      @@logger.error("Error determining admin email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end

  def signup(user,base_host)
    subject     'Sysmo SEEK account activation'
    recipients  user.person.email_with_name
    from        ''
    sent_on     Time.now

    body        :username=>user.login, :name=>user.person.name, :activation_code=>user.activation_code, :host=>base_host
  end

  def forgot_password(sent_at = Time.now)
    subject    'Mailer#forgot_password'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def welcome(user,base_host)
    subject    'Welcome to Sysmo SEEK'
    recipients user.person.email_with_name
    from       ''
    sent_on    Time.now
    
    body       :name=>user.person.name,:person=>user.person, :host=>base_host
  end

  def contact_admin_new_user_no_profile(details,user,base_host)
    
    subject    'Sysmo Member signed up'
    recipients admin_emails
    from       ''
    sent_on    Time.now
    
    body       :details=>details, :person=>user.person, :user=>user, :host=>base_host
  end

end
