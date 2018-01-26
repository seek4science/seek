class ContentBlobCleanerJob < SeekJob
  def follow_on_job?
    true
  end

  def follow_on_delay
    grace_period
  end

  def default_priority
    3
  end

  def self.create_initial_job
    new.queue_job
  end

  def perform_job(item)
    Rails.logger.info("Cleaning up content blob #{item.id}")
    item.reload
    item.destroy if item.asset.nil?
  end

  def gather_items
    ContentBlob.where('created_at < ?', grace_period.ago).select { |blob| blob.asset.nil? }
  end

  def allow_duplicate_jobs?
    false
  end

  # overidden to ignore_locked false by default
  def exists?(ignore_locked = false)
    super(ignore_locked)
  end

  # overidden to ignore_locked false by default
  def count(ignore_locked = false)
    super(ignore_locked)
  end

  def grace_period
    8.hours
  end
end
