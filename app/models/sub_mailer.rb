class SubMailer < ActionMailer::Base


  def send_digest_subscription person, activity_logs
    subject "#{person.user.name}: Your subscriptions for SEEK"
    recipients person.email_with_name
    from Seek::Config.noreply_sender
    sent_on Time.now
    content_type "text/html"
    body :activity_logs=> activity_logs
  end

  def send_immediate_subscription person, activity_log
    subject "#{person.user.name}: Your subscription on project - #{activity_log.referenced.name}"
    recipients person.email_with_name
    from Seek::Config.noreply_sender
    sent_on Time.now
    content_type "text/html"

    body :activity_log=> activity_log

  end
end