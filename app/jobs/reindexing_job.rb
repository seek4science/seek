class ReindexingJob

  @@my_yaml = ReindexingJob.new.to_yaml

  BATCHSIZE=15

  def perform
    todo = ReindexingQueue.all(:limit=>BATCHSIZE,:order=>:id).collect do |queued|
      todo = queued.item
      queued.destroy
      todo
    end
    todo.uniq.each do |item|
      begin
        item.solr_index!
      rescue Exception=>e
        ReindexingJob.add_items_to_queue(item)
      end
    end

    if ReindexingQueue.count>0 && !ReindexingJob.exists?
      Delayed::Job.enqueue(ReindexingJob.new,1,1.seconds.from_now)
    end
  end

  def self.add_items_to_queue items, t=1.seconds.from_now
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