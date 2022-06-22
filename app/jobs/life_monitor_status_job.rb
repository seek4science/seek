class LifeMonitorStatusJob < ApplicationJob
  PERIOD = 1.day.freeze
  BATCH_SIZE = 20

  def perform(offset = 0)
    # waiting for LifeMonitor::Rest::Client#list_workflows to be functional
    return
    return unless Seek::Config.life_monitor_enabled

    token = LifeMonitor::Oauth2::Client.new.get_token
    client = LifeMonitor::Rest::Client.new(token)
    response = client.list_workflows
    response['items'].each do |wf|
      workflow = Workflow.find_by_uuid(wf['uuid'])
      if workflow && wf['aggregate_test_status'].present?
        workflow_version = workflow.find_version(wf.dig('version', 'version'))
        if workflow_version
          disable_authorization_checks do
            workflow_version.workflow.update_test_status(wf['aggregate_test_status'], workflow_version.version)
          end
        end
      end
    end
  end
end
