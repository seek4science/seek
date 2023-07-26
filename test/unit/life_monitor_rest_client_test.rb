require 'test_helper'

class LifeMonitorRestClientTest < ActiveSupport::TestCase
  setup do
    @workflow = FactoryBot.create(:workflow_with_tests, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011', policy: FactoryBot.create(:downloadable_public_policy))
    @token = 'FUY30D5gtDOeEPE2qu0MbWg2afrrst4whOOB1zHDtF'
    @client = LifeMonitor::Rest::Client.new(@token, 'https://localhost:8443/')
  end

  test 'submit workflow' do
    assert @workflow.can_download?(nil)
    VCR.use_cassette('life_monitor/submit_workflow', match_requests_on: [:method]) do
      response = @client.submit(@workflow.latest_version)
      assert_equal @workflow.uuid, response.dig('uuid')
    end
  end

  test 'update workflow' do
    assert @workflow.can_download?(nil)
    VCR.use_cassette('life_monitor/update_workflow', match_requests_on: [:method]) do
      assert_nothing_raised do
        @client.update(@workflow.latest_version)
      end
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

  test 'non-submitted workflow version does not exist' do
    assert_equal 1, @workflow.latest_version.version

    disable_authorization_checks do
      @workflow.save_as_new_version
    end

    assert_equal 2, @workflow.reload.latest_version.version

    VCR.use_cassette('life_monitor/existing_workflow_get') do
      refute @client.exists?(@workflow.latest_version)
    end
  end

  test 'not submitted workflow does not exist' do
    VCR.use_cassette('life_monitor/non_existing_workflow_get') do
      refute @client.exists?(@workflow.latest_version)
    end
  end

  test 'list workflows' do
    VCR.use_cassette('life_monitor/list_workflows') do
      response = @client.list_workflows
      assert_equal 2, response['items'].count

      name = 'Concat two files'
      wf = response['items'].detect { |i| i['name'] == name }
      assert wf, "Couldn't find '#{name}' workflow in response"
      assert_equal 'all_failing', wf.dig('status', 'aggregate_test_status')

      name = 'sort-and-change-case'
      wf = response['items'].detect { |i| i['name'] == name }
      assert wf, "Couldn't find '#{name}' workflow in response"
      assert_equal 'all_passing', wf.dig('status', 'aggregate_test_status')
    end
  end
end
