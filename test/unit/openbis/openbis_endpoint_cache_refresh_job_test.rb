require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointCacheRefreshJobTest < ActiveSupport::TestCase

  def setup
    @endpoint = Factory(:openbis_endpoint)
    @job = OpenbisEndpointCacheRefreshJob.new(@endpoint)
    Delayed::Job.destroy_all #avoids jobs created from the after_create callback, this is tested for OpenbisEndpoint
  end

  test 'exists' do
    refute @job.exists?
    @job.queue_job
    assert @job.exists?
  end

  test 'queue' do
    assert_difference('Delayed::Job.count',1) do
      @job.queue_job
    end

    assert_no_difference('Delayed::Job.count') do
      @job.queue_job
    end

  end

  test 'defaults' do
    assert_equal 3,@job.default_priority
    refute @job.allow_duplicate_jobs?
    assert_equal 60.minutes,@job.follow_on_delay
  end

  test 'perform' do
    mock_openbis_calls
    key = @endpoint.space.cache_key(@endpoint.space_perm_id)
    @endpoint.clear_cache
    refute Rails.cache.exist?(key)
    @job.perform
    assert Rails.cache.exist?(key)
  end

end