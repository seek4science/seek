module BackgroundReindexing
  def queue_background_reindexing
    Rails.logger.info("About to reindex #{self.class.name} #{self.id}")
    ReindexingJob.add_items_to_queue self
  end
end