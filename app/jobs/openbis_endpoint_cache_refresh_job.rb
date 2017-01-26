# job to periodically clear and refresh the cache
class OpenbisEndpointCacheRefreshJob < SeekJob
  attr_accessor :openbis_endpoint_id

  def initialize(openbis_endpoint)
    @openbis_endpoint_id = openbis_endpoint.id
  end

  def perform_job(endpoint)
    if endpoint.test_authentication
      endpoint.clear_cache
      space = endpoint.space
      if space
        space.datasets each do |dataset|
          dataset.dataset_files if dataset
        end
      end
    end
  end

  def gather_items
    [endpoint].compact
  end

  def allow_duplicate_jobs?
    false
  end

  def default_priority
    3
  end

  def follow_on_delay
    60.minutes
  end

  def self.create_initial_jobs
    OpenbisEndpoint.all.each(&:create_refresh_cache_job)
  end

  private

  def endpoint
    OpenbisEndpoint.find_by_id(openbis_endpoint_id)
  end
end
