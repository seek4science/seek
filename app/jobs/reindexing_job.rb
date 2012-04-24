class ReindexingJob

  @@my_yaml = ReindexingJob.new.to_yaml

  def perform
    todo = ReindexingQueue.find(:all).collect do |queued|
      todo = queued.item
      queued.destroy
      todo
    end
    todo.uniq.each do |item|
      item.solr_index!
    end
  end

  def add_items_to_queue items, t=1.seconds.from_now
    items = Array(items)
    disable_authorization_checks do
      items.uniq.each do |item|
        ReindexingQueue.create :item=>item
      end
    end
    Delayed::Job.enqueue(ReindexingJob.new, 1, t) unless ReindexingJob.exists?
  end

  def self.exists?
    Delayed::Job.find(:first,:conditions=>['handler = ? AND locked_at IS ?',@@my_yaml,nil]) != nil
  end
end