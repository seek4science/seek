class LifeMonitorStatusJob < ApplicationJob
  PERIOD = 1.day.freeze

  def perform(offset = 0)
    return unless Seek::Config.life_monitor_enabled
    token = LifeMonitor::Oauth2::Client.new.get_token
    client = LifeMonitor::Rest::Client.new(token)
    response = client.list_workflows
    response['items'].each do |wf|
      workflow = Workflow.find_by_uuid(wf['uuid'])
      if workflow
        Rails.cache.write("lifemonitor-results-#{workflow.cache_key}", { date: Time.now, response: wf })
        wf['versions'].each do |wfv|
          workflow_version = workflow.find_version(wfv['version'])
          if workflow_version
            status = wfv.dig('status', 'aggregate_test_status')
            disable_authorization_checks do
              workflow.update_test_status(status, workflow_version.version)
            end
          end
        end
      end
    end
  end
end
