class SubMailer < ActionMailer::Base


  def send_digest_subscription person,activity_logs,subscription_type=""

    subject "Your #{subscription_type} subscriptions for SEEK"
    recipients person.email_with_name
    from Seek::Config.noreply_sender
    reply_to person.email_with_name
    sent_on Time.now
    content_type "text/html"
    body :activity_logs=> activity_logs

  end

  def send_immediate_subscription activity_log


    subject "Your subscription on project - #{activity_log.referenced.name}"
    recipients activity_log.culprit.person.email_with_name
    from Seek::Config.noreply_sender
    reply_to activity_log.culprit.person.email_with_name
    sent_on Time.now
    content_type "text/html"

    body :activity_log=> activity_log

  end
end