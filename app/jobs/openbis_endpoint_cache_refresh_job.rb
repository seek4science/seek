# job to periodically clear and refresh the cache
class OpenbisEndpointCacheRefreshJob < SeekJob
  attr_accessor :openbis_endpoint_id

  def initialize(openbis_endpoint)
    @openbis_endpoint_id = openbis_endpoint.id
  end

  def perform_job(endpoint)
    endpoint.refresh_metadata
  end

  def gather_items
    [endpoint].compact
  end

  def default_priority
    3
  end

  def follow_on_delay
    if endpoint
      endpoint.refresh_period_mins.minutes
    else
      120.minutes
    end
  end

  def follow_on_job?
    Seek::Config.openbis_enabled && endpoint # don't follow on if the endpoint no longer exists
  end

  def self.queue_jobs
    return unless Seek::Config.openbis_enabled
    OpenbisEndpoint.find_each do |endpoint|
      endpoint.create_refresh_metadata_job if endpoint.due_cache_refresh?
    end
  end

  private

  def endpoint
    OpenbisEndpoint.find_by_id(openbis_endpoint_id)
  end
end
