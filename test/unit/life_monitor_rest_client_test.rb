require 'test_helper'

class LifeMonitorRestClientTest < ActiveSupport::TestCase
  setup do
    @workflow = Factory(:public_workflow, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011')
    @token = 'FUY30D5gtDOeEPE2qu0MbWg2afrrst4whOOB1zHDtF'
    @client = LifeMonitor::Rest::Client.new(@token, 'https://localhost:8443/')
  end

  test 'submit workflow' do
    skip('WIP')
    VCR.use_cassette('life_monitor/submit_workflow', match_requests_on: [:method]) do
      response = @client.submit(@workflow.latest_version)
      assert_equal @workflow.uuid, response.dig('uuid')
    end
  end

  test 'get workflow status' do
    VCR.use_cassette('life_monitor/workflow_status') do
      response = @client.status(@workflow.latest_version)
      assert_equal 'not_available', response['aggregate_test_status']
      assert_equal @workflow.uuid, response.dig('uuid')
    end
  end

  test 'submitted workflow exists' do
    VCR.use_cassette('life_monitor/existing_workflow_get') do
      assert @client.exists?(@workflow.latest_version)
    end
  end

  test 'not submitted workflow does not exist' do
    another_workflow = Factory(:public_workflow, uuid: 'f7536a50-d3a0-013a-377e-000c29a94011')
    VCR.use_cassette('life_monitor/non_existing_workflow_get') do
      refute @client.exists?(another_workflow.latest_version)
    end
  end
end
