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
    stub_request(:get, /https:\/\/localhost:8000\/workflows\/[-a-z0-9A-Z]+\/1\/status/)
        .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/life_monitor_status.json"), status: 200)
    stub_request(:post, "https://localhost:8000/oauth2/token")
        .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/life_monitor_token.json"), status: 200)

    # Create <BATCH_SIZE> + 1 monitored workflow versions, so 2 batches of emails will need to be sent
    FactoryGirl.create_list(:monitored_workflow, LifeMonitorStatusJob::BATCH_SIZE + 1)
    assert_equal LifeMonitorStatusJob::BATCH_SIZE + 1, Workflow::Version.where(monitored: true).count

    # checks <BATCH_SIZE> statuses are updated for the first batch
    assert_difference('Workflow.where(test_status: nil).count', -LifeMonitorStatusJob::BATCH_SIZE) do
      # The follow-on job enqueued with an offset of <BATCH_SIZE>
      assert_enqueued_with(job: LifeMonitorStatusJob, args: [LifeMonitorStatusJob::BATCH_SIZE]) do
        LifeMonitorStatusJob.perform_now
      end
    end

    # ..and 1 status is updated for the 2nd batch
    assert_difference('Workflow.where(test_status: nil).count', -1) do
      # no new jobs should have been created, since there is no need for a new batch
      assert_no_enqueued_jobs(only: LifeMonitorStatusJob) do
        LifeMonitorStatusJob.perform_now(LifeMonitorStatusJob::BATCH_SIZE)
      end
    end
  end
end
