class ContentBlobCleanerJob < SeekJob
  include PeriodicRegularSeekJob

  def follow_on_delay
    grace_period
  end

  def default_priority
    3
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

  def grace_period
    8.hours
  end

  def self.create_initial_job
    new.queue_job
  end
end
