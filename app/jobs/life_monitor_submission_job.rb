class LifeMonitorSubmissionJob < ApplicationJob
  def perform(workflow_version)
    return
    return unless Seek::Config.life_monitor_enabled
    return if workflow_version.monitored
    token = LifeMonitor::Oauth2::Client.new.get_token
    client = LifeMonitor::Rest::Client.new(token)
    unless client.exists?(workflow_version)
      response = client.submit(workflow_version)
      if response['uuid'] == workflow_version.uuid
        workflow_version.update_column(:monitored, true)
      end
    end
  end
end
