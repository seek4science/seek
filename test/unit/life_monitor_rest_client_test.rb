require 'test_helper'

class LifeMonitorRestClientTest < ActiveSupport::TestCase
  setup do
    @workflow = Factory(:public_workflow, uuid: '56c50ac0-529b-0139-9132-000c29a94011')
    @token = '0KFv5bXGD4FhEFTuqLJ8uAaJVNI0cNIgYeIeWR5XqR'
    @client = LifeMonitor::Rest::Client.new(@token, 'https://localhost:8000/')
  end

  test 'submit workflow' do
    VCR.use_cassette('life_monitor/submit_workflow') do
      response = @client.submit(@workflow.latest_version)
      assert_equal @workflow.uuid, response['wf_uuid']
    end
  end

  test 'get workflow status' do
    VCR.use_cassette('life_monitor/workflow_status') do
      response = @client.status(@workflow.latest_version)
      assert_equal 'not_available', response['aggregate_test_status']
      assert_equal @workflow.uuid, response.dig('workflow', 'uuid')
    end
  end

  test 'submitted workflow exists' do
    VCR.use_cassette('life_monitor/existing_workflow_get') do
      assert @client.exists?(@workflow.latest_version)
    end
  end

  test 'not submitted workflow does not exist' do
    VCR.use_cassette('life_monitor/non_existing_workflow_get') do
      refute @client.exists?(@workflow.latest_version)
    end
  end
end
