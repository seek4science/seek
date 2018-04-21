# job to periodically clear and refresh the cache
class OpenbisSyncJob < SeekJob
  attr_accessor :openbis_endpoint_id

  # debug is with puts so it can be easily seen on tests screens
  DEBUG = Seek::Config.openbis_debug ? true : false

  def initialize(openbis_endpoint, batch_size = 10)
    @openbis_endpoint_id = openbis_endpoint.id
    @batch_size = batch_size || 10
  end

  def perform_job(obis_asset)
    puts "starting obis sync of #{obis_asset.class}:#{obis_asset.id} perm_id: #{obis_asset.external_id}" if DEBUG
    Rails.logger.info "starting obis sync of #{obis_asset.class}:#{obis_asset.id} perm_id: #{obis_asset.external_id}" if DEBUG

    errs = []
    obis_asset.reload

    errs = seek_util.sync_external_asset(obis_asset) unless obis_asset.synchronized?

    if errs.empty?
      Rails.logger.info "successful obis sync of OBisAsset:#{obis_asset.id} perm_id: #{obis_asset.external_id}" if DEBUG
    else
      msg = "Sync issues with OBisAsset:#{obis_asset.id} perm_id: #{obis_asset.external_id}\n#{errs.join(',\n')}"
      puts msg if DEBUG
      Rails.logger.error msg
    end
  end

  def gather_items
    # TODO what to do with failed, we dont won't the same failed blocking the queue but rather moved to the end
    needs_refresh.to_a
  end

  def allow_duplicate_jobs?
    false
  end

  def default_priority
    3
  end

  def follow_on_delay
    return 1.seconds if errorfree_needs_refresh.count > 0
    # if they failed once they will fail if checked too soon
    return 5.minutes if needs_refresh.count > 0

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
        .order(:sync_state, :synchronized_at)
        .limit(@batch_size)

  end

  def errorfree_needs_refresh
    service = endpoint # to prevent multiple callas

    old = DateTime.now - service.refresh_period_mins.minutes
    service.external_assets.where("synchronized_at < ? AND sync_state = ?", old, ExternalAsset.sync_states[:refresh])
        .order(:synchronized_at)
        .limit(@batch_size)

  end

  def self.create_initial_jobs
    OpenbisEndpoint.all.each { |point| OpenbisSyncJob.new(point).queue_job }
  end

  def seek_util
    @seek_util ||= Seek::Openbis::SeekUtil.new
  end

  private

  def endpoint
    @endpoint ||= OpenbisEndpoint.find_by_id(openbis_endpoint_id)
  end
end
