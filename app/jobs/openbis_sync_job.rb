# job to periodically take OBIS assets that are due to synchronization
# and refresh their content with the current state in OBIS
# It can also follow the dependent Objects/DataSets and register them if so configured
class OpenbisSyncJob < SeekJob
  attr_accessor :openbis_endpoint_id

  # debug is with puts so it can be easily seen on tests screens
  DEBUG = Seek::Config.openbis_debug ? true : false

  def initialize(openbis_endpoint, batch_size = 20)
    @openbis_endpoint_id = openbis_endpoint.id
    @batch_size = batch_size || 20
  end

  def perform_job(obis_asset)
    if DEBUG
      puts "starting obis sync of #{obis_asset.class}:#{obis_asset.id} perm_id: #{obis_asset.external_id}"
      Rails.logger.info "starting obis sync of #{obis_asset.class}:#{obis_asset.id} perm_id: #{obis_asset.external_id}"
    end

    errs = []
    obis_asset.reload

    errs = seek_util.sync_external_asset(obis_asset) unless obis_asset.synchronized?

    if obis_asset.failed? && obis_asset.failures > failure_threshold
      obis_asset.sync_state = :fatal
      obis_asset.err_msg = 'Stopped sync: ' + obis_asset.err_msg
      obis_asset.save
      Rails.logger.error "Marked OBisAsset:#{obis_asset.id} perm_id: #{obis_asset.external_id} as fatal no more sync"
    else
      # allways touch asset so its updated_at stamp is modified as it is used for queuing entiries
      obis_asset.touch
    end

    if errs.empty?
      Rails.logger.info "successful obis sync of OBisAsset:#{obis_asset.id} perm_id: #{obis_asset.external_id}" if DEBUG
    else
      msg = "Sync issues with OBisAsset:#{obis_asset.id} perm_id: #{obis_asset.external_id}\n#{errs.join(',\n')}"
      puts msg if DEBUG
      Rails.logger.error msg
    end
  end

  def gather_items
    need_sync.to_a
  end

  def allow_duplicate_jobs?
    false
  end

  def default_priority
    3
  end

  def follow_on_delay
    needed = need_sync.count
    Rails.logger.info "OBis syn will follow with #{needed} items" if DEBUG
    return 1.seconds if need_sync.count > 0

    if endpoint
      endpoint.refresh_period_mins.minutes
    else
      120.minutes
    end
  end

  def follow_on_job?
    Rails.logger.info "Follow? count #{count} #{count(true)}" if DEBUG
    return false unless Seek::Config.openbis_enabled && Seek::Config.openbis_autosync
    (count(true) < 1) && endpoint # don't follow on if the endpoint no longer exists
  end

  # overidden to ignore_locked false by default
  def exists?(ignore_locked = false)
    super(ignore_locked)
  end

  # overidden to ignore_locked false by default
  def count(ignore_locked = false)
    super(ignore_locked)
  end

  def need_sync
    # bussines rule
    # - status refresh or failed
    # - synchronized_at before (Now - endpoint refresh)
    # - for failed: last update before (Now - endpoint_refresh/2) to prevent constant checking of failed entries)
    # - fatal not returned

    service = endpoint # to prevent multiple calls

    old = DateTime.now - service.refresh_period_mins.minutes
    too_fresh = DateTime.now - (service.refresh_period_mins / 2).minutes

    service.external_assets
           .where('synchronized_at < ? AND (sync_state = ? OR (updated_at < ? AND sync_state =?))',
                  old, ExternalAsset.sync_states[:refresh], too_fresh, ExternalAsset.sync_states[:failed])
           .order(:sync_state, :updated_at)
           .limit(@batch_size)
  end

  def failure_threshold
    t = (2.days / endpoint.refresh_period_mins.minutes).to_i
    t < 3 ? 3 : t
  end

  def self.create_initial_jobs
    return unless Seek::Config.openbis_enabled && Seek::Config.openbis_autosync
    OpenbisEndpoint.all.each(&:create_sync_metadata_job)
    # OpenbisEndpoint.all.each { |point| OpenbisSyncJob.new(point).queue_job }
  end

  def seek_util
    @seek_util ||= Seek::Openbis::SeekUtil.new
  end

  private

  def endpoint
    @endpoint ||= OpenbisEndpoint.find_by_id(openbis_endpoint_id)
  end
end
