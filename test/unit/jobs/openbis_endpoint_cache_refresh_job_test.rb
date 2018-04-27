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

  test 'perform_job calls refresh on endpoint' do
    endpoint = MockEndpoint.new
    @job = OpenbisEndpointCacheRefreshJob.new(endpoint)
    @job.perform_job(endpoint)
    assert_equal 1, endpoint.refreshed
  end

  test 'create_initial_jobs creates jobs for each endpoint' do
    endpoint1 = OpenbisEndpoint.new project: Factory(:project), username: 'fred', password: 'frog',
                                    web_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    as_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    dss_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    space_perm_id: 'space1',
                                    refresh_period_mins: 60

    endpoint2 = OpenbisEndpoint.new project: Factory(:project), username: 'fred', password: 'frog',
                                    web_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    as_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    dss_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    space_perm_id: 'space2',
                                    refresh_period_mins: 60

    disable_authorization_checks do
      assert endpoint1.save
      assert endpoint2.save
    end

    diff = OpenbisEndpoint.count

    Delayed::Job.destroy_all
    assert_difference('Delayed::Job.count', diff) do
      OpenbisEndpointCacheRefreshJob.create_initial_jobs
    end
    assert OpenbisEndpointCacheRefreshJob.new(endpoint1).exists?
    assert OpenbisEndpointCacheRefreshJob.new(endpoint2).exists?


    Seek::Config.openbis_enabled = false
    Delayed::Job.destroy_all
    assert_no_difference('Delayed::Job.count') do
      OpenbisEndpointCacheRefreshJob.create_initial_jobs
    end
  end

  class MockEndpoint
    attr_accessor :refreshed, :id

    def initialize
      @refreshed = 0
      @id = 1
    end

    def refresh_metadata
      @refreshed += 1
    end
  end
end
