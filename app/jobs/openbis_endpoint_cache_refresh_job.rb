# job to periodically clear and refresh the cache
class OpenbisEndpointCacheRefreshJob < SeekJob
  attr_accessor :openbis_endpoint_id

  def initialize(openbis_endpoint)
    @openbis_endpoint_id = openbis_endpoint.id
  end

  def perform_job(endpoint)
    if endpoint.test_authentication
      endpoint.clear_metadata_store
      space = endpoint.space
      if space
        space.datasets.each do |dataset|
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
    if endpoint
      endpoint.refresh_period_mins.minutes
    else
      120.minutes
    end
  end

  def follow_on_job?
    true && endpoint #don't follow on if the endpoint no longer exists
  end

  # overidden to ignore_locked false by default
  def exists?(ignore_locked = false)
    super(ignore_locked)
  end

  # overidden to ignore_locked false by default
  def count(ignore_locked = false)
    super(ignore_locked)
  end

  def self.create_initial_jobs
    OpenbisEndpoint.all.each(&:create_refresh_cache_job)
  end

  private

  def endpoint
    OpenbisEndpoint.find_by_id(openbis_endpoint_id)
  end
end
