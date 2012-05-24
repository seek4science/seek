module BackgroundReindexing
  def queue_background_reindexing
        unless (self.changed - ["updated_at", "last_used_at"]).empty?
          Rails.logger.info("About to reindex #{self.class.name} #{self.id}")
          ReindexingJob.add_items_to_queue self
        end
  end
end