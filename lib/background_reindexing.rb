module BackgroundReindexing
  def queue_background_reindexing
        unless (self.changed - ["updated_at", "last_used_at"]).empty?
          Rails.logger.info("About to reindex #{self.class.name} #{self.id}")
          ReindexingQueue.create :item=>self
          Delayed::Job.enqueue(ReindexingJob.new, 0, 1.seconds.from_now) unless ReindexingJob.exists?
        end
  end
end