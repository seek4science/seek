class SubMailer < ActionMailer::Base


  def send_subscription subscription,new_req=true,update_req=true,delete_req=true

    subject "Your subscription on project - #{subscription.project.name}"
    recipients subscription.person.email_with_name
    from Seek::Config.noreply_sender
    reply_to subscription.person.email_with_name
    sent_on Time.now
    content_type "text/html"
    resources = (subscription.respond_to? :subscribed_resource_types)? subscription.subscribed_resource_types : [subscription.subscribable_type]

    body :resources => resources,:new_req=>new_req,:update_req=>update_req,:delete_req=>delete_req,:project=>subscription.project

  end

  def send_specific_subscription activity_log


    subject "Your subscription on project - #{activity_log.referenced.name}"
    recipients activity_log.culprit.person.email_with_name
    from Seek::Config.noreply_sender
    reply_to activity_log.culprit.person.email_with_name
    sent_on Time.now
    content_type "text/html"

    body :activity_log=> activity_log

  end
end