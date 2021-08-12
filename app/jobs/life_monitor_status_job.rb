class LifeMonitorStatusJob < ApplicationJob
  PERIOD = 1.day.freeze
  BATCH_SIZE = 20

  def perform(offset = 0)
    return unless Seek::Config.life_monitor_enabled

    versions = Workflow::Version.where(monitored: true).offset(offset).limit(BATCH_SIZE)
    if versions.any?
      token = LifeMonitor::Oauth2::Client.new.get_token
      client = LifeMonitor::Rest::Client.new(token)
      versions.find_each do |workflow_version|
        response = client.status(workflow_version)
        if response['aggregate_test_status'].present?
          disable_authorization_checks do
            workflow_version.workflow.update_test_status(response['aggregate_test_status'], workflow_version.version)
          end
        end
      end
    end

    offset += BATCH_SIZE

    self.class.perform_later(offset) if offset < Workflow::Version.where(monitored: true).count
  end
end
