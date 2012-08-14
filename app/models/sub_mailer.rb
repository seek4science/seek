class
SubMailer < ActionMailer::Base


  def send_digest_subscription person, activity_logs, frequency
    subject "#{Seek::Config.application_title} Subscription Report"
    recipients person.email_with_name
    from Seek::Config.noreply_sender
    sent_on Time.now
    content_type "text/html"
    body :activity_logs=> activity_logs, :person => person, :frequency => frequency
  end

  def send_immediate_subscription person, activity_log
    template "send_digest_subscription"
    send_digest_subscription person, [activity_log], 'immediately'
  end
end