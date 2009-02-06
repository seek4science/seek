class Mailer < ActionMailer::Base
  
  def admin_emails
    #TODO: fetch from database
    ['stuzart@gmail.com']
  end

  def signup(sent_at = Time.now)
    subject    'Mailer#signup'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def forgot_password(sent_at = Time.now)
    subject    'Mailer#forgot_password'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def contact_admin_new_user_no_profile(details,person)
    subject    'Mailer#contact_admin'
    recipients admin_emails
    from       ''
    sent_on    Time.now
    
    body       :greeting => 'Hi,'
  end

end
