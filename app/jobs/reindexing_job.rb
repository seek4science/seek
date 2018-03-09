class ReindexingJob < SeekJob
  BATCHSIZE = 100

  def perform_job(item)
    if Seek::Config.solr_enabled
      item.solr_index!
    end
  end

  def gather_items
    ReindexingQueue.order('id ASC').limit(BATCHSIZE).collect do |queued|
      take_queued_item(queued)
    end.uniq.compact
  end

  def default_priority
    2
  end

  def follow_on_job?
    ReindexingQueue.count > 0 && !exists?
  end

  def add_items_to_queue(items, time = default_delay.from_now, priority = default_priority)
    items = Array(items)

    disable_authorization_checks do
      items.uniq.each do |item|
        ReindexingQueue.create item: item
      end
    end
    queue_job(priority, time) unless exists?
  end
end
