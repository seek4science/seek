class SubMailer < ActionMailer::Base

  default :from=>Seek::Config.noreply_sender

  def send_digest_subscription person, activity_logs, frequency
    @activity_logs = activity_logs
    @person = person
    @frequency = frequency
    mail(:to=>person.email_with_name,:subject=>"#{Seek::Config.application_title} Subscription Report")
  end

  def send_immediate_subscription person, activity_log
    send_digest_subscription person, [activity_log], 'immediately'
  end
end