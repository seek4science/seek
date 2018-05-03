# job to periodically fetch assets to potentially create mem leak
class OpenbisFakeJob < SeekJob
  DEBUG = false

  def initialize(name, batch_size = 10)
    @name = name
    @batch_size = batch_size || 10
  end

  def perform_job(item)
    Rails.logger.info "starting fake job of #{item.class}:#{item.id}" if DEBUG

    item.reload

    sleep item.title.length.even? ? 0.1 : 0.5

    item.touch

    Rails.logger.info "successful fake job of #{item.class}:#{item.id}" if DEBUG
  end

  def gather_items
    # Rails.logger.info "Before job\n#{ObjectSpace.count_objects}"
    assets_and_assays
  end

  def allow_duplicate_jobs?
    false
  end

  def default_priority
    3
  end

  def follow_on_delay
    1.seconds
  end

  def follow_on_job?
    # Rails.logger.info "After job\n#{ObjectSpace.count_objects}"
    true
  end

  # overidden to ignore_locked false by default
  def exists?(ignore_locked = false)
    super(ignore_locked)
  end

  # overidden to ignore_locked false by default
  def count(ignore_locked = false)
    super(ignore_locked)
  end

  def assets_and_assays
    rnd_assets.to_a | rnd_assays.to_a
  end

  def rnd_assets
    first = DataFile.first.id + 1
    last = DataFile.last.id + 1
    partition = rand(first..last)

    DataFile.where('id < ?', partition)
            .limit(@batch_size)
  end

  def rnd_assays
    first = Assay.first.id + 1
    last = Assay.last.id + 1
    partition = rand(first..last)

    Assay.where('id < ?', partition)
         .limit(@batch_size)
  end

  def self.create_initial_jobs
    OpenbisFakeJob.new('fake1').queue_job
  end
end
