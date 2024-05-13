class ReindexingJob < BatchJob
  BATCHSIZE = 100
  queue_as QueueNames::INDEXING

  def perform
    if Seek::Config.solr_enabled
      super
      Sunspot.commit
    end
  end

  def perform_job(item)
    begin
      item.solr_index
    rescue => e
      Rails.logger.error "Could not index #{item} #{e.class} #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Sunspot.commit
      raise e
    end
  end

  def gather_items
    ReindexingQueue.dequeue(BATCHSIZE).compact
  end

  def follow_on_job?
    Seek::Config.solr_enabled && ReindexingQueue.any?
  end

  def timelimit
    1.hour
  end
end
