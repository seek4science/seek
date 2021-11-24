class SubMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)

  def send_digest_subscription person, activity_logs, frequency
    @activity_logs = activity_logs
    @person = person
    @frequency = frequency
    mail(:from=>Seek::Config.noreply_sender,:to=>person.email_with_name,:subject=>"The #{Seek::Config.instance_name} Subscription Report") do |format|
      format.html { render :send_digest_subscription}
    end
  end

  def send_immediate_subscription person, activity_log
    send_digest_subscription person, [activity_log], 'immediately'
  end
end