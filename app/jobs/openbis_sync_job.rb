# job to periodically clear and refresh the cache
class OpenbisSyncJob < SeekJob
  attr_accessor :openbis_endpoint_id

  def initialize(openbis_endpoint, batch_size = 10)
    @openbis_endpoint_id = openbis_endpoint.id
    @batch_size = batch_size || 10
  end

  def perform_job(item)
    puts "performing sync job on #{item}"
    Rails.logger.info "performing sync job on #{item}"
    # endpoint.refresh_metadata
  end

  def gather_items
    needs_refresh.to_a
  end

  def allow_duplicate_jobs?
    false
  end

  def default_priority
    3
  end

  def follow_on_delay
    return 1.seconds if needs_refresh.count > 0

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

  def needs_refresh
    service = endpoint # to prevent multiple callas

    old = DateTime.now - service.refresh_period_mins.minutes
    service.external_assets.where("synchronized_at < ? AND sync_state != ?", old, ExternalAsset.sync_states[:synchronized])
        .order(:synchronized_at)
        .limit(@batch_size)

  end

  def self.create_initial_jobs
    OpenbisEndpoint.all.each {|point| OpenbisSyncJob.new(point).queue_job}
  end

  private

  def endpoint
    OpenbisEndpoint.find_by_id(openbis_endpoint_id)
  end
end
