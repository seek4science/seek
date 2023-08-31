require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointCacheRefreshJobTest < ActiveSupport::TestCase
  test 'perform_job calls refresh on endpoint' do
    endpoint = MockEndpoint.new
    OpenbisEndpointCacheRefreshJob.perform_now(endpoint)
    assert_equal 1, endpoint.refreshed
  end

  test 'queue_timed_jobs creates jobs for each endpoint needing a cache refresh' do
    OpenbisEndpoint.delete_all
    endpoint1 = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: 'frog',
                                    web_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    as_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    dss_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    space_perm_id: 'space1',
                                    refresh_period_mins: 60

    endpoint2 = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'fred', password: 'frog',
                                    web_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    as_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    dss_endpoint: 'http://my-openbis.org/doesnotmatter',
                                    space_perm_id: 'space2',
                                    refresh_period_mins: 60

    not_needing_refresh = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, last_cache_refresh: Time.now)
    # Reload before getting timestamp to avoid comparison error later: No visible difference in the ActiveSupport::TimeWithZone#inspect output
    not_needing_refresh_timestamp = not_needing_refresh.reload.last_cache_refresh

    disable_authorization_checks do
      assert endpoint1.save
      assert endpoint2.save
    end

    assert_nil endpoint1.last_cache_refresh
    assert_nil endpoint2.last_cache_refresh
    assert_enqueued_jobs(2, only: OpenbisEndpointCacheRefreshJob) do
      OpenbisEndpointCacheRefreshJob.queue_timed_jobs
    end

    OpenbisEndpointCacheRefreshJob.perform_now(endpoint1)
    OpenbisEndpointCacheRefreshJob.perform_now(endpoint2)

    refute_nil endpoint1.reload.last_cache_refresh
    refute_nil endpoint2.reload.last_cache_refresh
    assert_equal not_needing_refresh_timestamp, not_needing_refresh.reload.last_cache_refresh

    endpoint3 = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60)

    assert_enqueued_jobs(1, only: OpenbisEndpointCacheRefreshJob) do
      assert_enqueued_with(job: OpenbisEndpointCacheRefreshJob, args: [endpoint3]) do
        OpenbisEndpointCacheRefreshJob.queue_timed_jobs
      end
    end
  end

  test 'queue_timed_jobs does nothing if openbis disabled' do
    with_config_value(:openbis_enabled, false) do
      FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60)

      assert_no_enqueued_jobs(only: OpenbisEndpointCacheRefreshJob) do
        OpenbisEndpointCacheRefreshJob.queue_timed_jobs
      end
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

    def persisted?
      true
    end
  end
end
