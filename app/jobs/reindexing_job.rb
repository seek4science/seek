class ReindexingJob < BatchJob
  BATCHSIZE = 100

  def perform
    super if Seek::Config.solr_enabled
  end

  def perform_job(item)
    begin
      item.solr_index!
    rescue => e
      Rails.logger.error "Could not index #{item} #{e.class} #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def gather_items
    ReindexingQueue.dequeue(BATCHSIZE).compact
  end

  def follow_on_job?
    ReindexingQueue.any?
  end
end
