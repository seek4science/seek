class Mailer < ActionMailer::Base
  
  def admin_emails
    #TODO: fetch from database
    ['stuzart@gmail.com']
  end

  def signup(user,base_host)
    subject     'Sysmo SEEK account activation'
    recipients  user.person.email
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

  def contact_admin_new_user_no_profile(details,user,base_host)
    
    subject    'Sysmo Member signed up'
    recipients admin_emails
    from       ''
    sent_on    Time.now
    
    body       :details=>details, :person=>user.person, :user=>user, :host=>base_host
  end

end
