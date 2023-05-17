require 'test_helper'

class LifeMonitorStatusJobTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.life_monitor_enabled
    Seek::Config.life_monitor_enabled = true
  end

  def teardown
    Seek::Config.life_monitor_enabled = @val
  end

  test 'perform' do
    VCR.use_cassette('life_monitor/get_token') do
      VCR.use_cassette('life_monitor/list_workflows') do
        workflow = FactoryBot.create(:workflow_with_tests, policy: FactoryBot.create(:public_policy), uuid: '1493b330-d44b-013a-df8a-000c29a94011', title: 'sort-and-change-case')
        all_failing = FactoryBot.create(:workflow_with_tests, policy: FactoryBot.create(:public_policy), uuid: '86da0a30-d2cd-013a-a07d-000c29a94011', title: 'Concat two files')
        disable_authorization_checks do
          FactoryBot.create(:ro_crate_with_tests, asset_version: 2, asset: workflow)
          workflow.save_as_new_version
        end
        some_passing = workflow.find_version(1)
        all_passing = workflow.find_version(2)

        assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
          assert_difference('Workflow.where(test_status: nil).count', -2) do
            LifeMonitorStatusJob.perform_now
          end
        end

        assert_equal :some_passing, some_passing.reload.test_status
        assert_equal :all_passing, workflow.reload.test_status
        assert_equal :all_passing, all_passing.reload.test_status
        assert_equal :all_failing, all_failing.reload.test_status
      end
    end
  end

  test 'perform for git workflow' do
    VCR.use_cassette('life_monitor/get_token') do
      VCR.use_cassette('life_monitor/list_workflows') do
        workflow = FactoryBot.create(:ro_crate_git_workflow_with_tests, uuid: '1493b330-d44b-013a-df8a-000c29a94011', title: 'sort-and-change-case', policy: FactoryBot.create(:public_policy))
        all_failing = FactoryBot.create(:local_ro_crate_git_workflow_with_tests, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011', title: 'Concat two files', policy: FactoryBot.create(:public_policy))
        disable_authorization_checks do
          workflow.save_as_new_git_version
        end
        some_passing = workflow.find_version(1)
        all_passing = workflow.find_version(2)

        assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
          assert_difference('Workflow.where(test_status: nil).count', -2) do
            LifeMonitorStatusJob.perform_now
          end
        end

        assert_equal :some_passing, some_passing.reload.test_status
        assert_equal :all_passing, workflow.reload.test_status
        assert_equal :all_passing, all_passing.reload.test_status
        assert_equal :all_failing, all_failing.reload.test_status
      end
    end
  end
end
