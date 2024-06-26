class LifeMonitorSubmissionJob < ApplicationJob
  retry_on RestClient::Exception, wait: 10.minutes, attempts: 3 do |exception|
    handle_exception(exception)
  end

  def perform(workflow_version)
    return unless Seek::Config.life_monitor_enabled

    token = LifeMonitor::Oauth2::Client.new.get_token
    client = LifeMonitor::Rest::Client.new(token)

    if client.exists?(workflow_version)
      client.update(workflow_version)
    else
      client.submit(workflow_version)
    end
  end
end
