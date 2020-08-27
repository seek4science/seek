class ReindexingJob < SeekJob
  BATCHSIZE = 100

  def perform_job(item)
    if Seek::Config.solr_enabled
      begin
        item.solr_index!
      rescue => e
        Rails.logger.error "Could not index #{item} #{e.class} #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    end
  end

  def gather_items
    ReindexingQueue.dequeue(BATCHSIZE)
  end

  def default_priority
    2
  end

  def follow_on_job?
    ReindexingQueue.any? && !exists?
  end
end
