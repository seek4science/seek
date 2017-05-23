require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointCacheRefreshJobTest < ActiveSupport::TestCase
  def setup
    @endpoint = Factory(:openbis_endpoint, refresh_period_mins: 88)
    @job = OpenbisEndpointCacheRefreshJob.new(@endpoint)
    Delayed::Job.destroy_all # avoids jobs created from the after_create callback, this is tested for OpenbisEndpoint
  end

  test 'exists' do
    refute @job.exists?
    @job.queue_job
    assert @job.exists?
  end

  test 'queue' do
    assert_difference('Delayed::Job.count', 1) do
      @job.queue_job
    end

    assert_no_difference('Delayed::Job.count') do
      @job.queue_job
    end
  end

  test 'follow on delay' do
    assert_equal 88.minutes, @job.follow_on_delay
    disable_authorization_checks { @endpoint.update_attributes(refresh_period_mins: 299) }
    assert_equal 299.minutes, @job.follow_on_delay
  end

  test 'delete jobs' do
    @job.queue_job
    assert_difference('Delayed::Job.count', -1) do
      @job.delete_jobs
    end
    refute @job.exists?
  end

  test 'defaults' do
    assert_equal 3, @job.default_priority
    refute @job.allow_duplicate_jobs?
    assert @job.follow_on_job?
  end

  test 'perform' do
    mock_openbis_calls
    key = @endpoint.space.cache_key(@endpoint.space_perm_id)
    store = @endpoint.metadata_store
    @endpoint.clear_metadata_store
    refute store.exist?(key)
    @job.perform
    assert store.exist?(key)
  end
end
