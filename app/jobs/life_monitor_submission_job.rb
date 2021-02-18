class LifeMonitorSubmissionJob < ApplicationJob
  def perform(workflow_version)
    token = LifeMonitor::Oauth2::Client.new.get_token
    client = LifeMonitor::Rest::Client.new(token)
    client.submit(workflow_version)
  end
end
