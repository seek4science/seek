class ReindexingJob

  @@my_yaml = ReindexingJob.new.to_yaml

  BATCHSIZE=10
  DEFAULT_PRIORITY=2

  def perform
    todo = ReindexingQueue.order("id ASC").limit(BATCHSIZE).collect do |queued|
      todo = queued.item
      queued.destroy
      todo
    end
    if Seek::Config.solr_enabled
      todo.uniq.each do |item|
        begin
          item.solr_index!
        rescue Exception => e
          #ReindexingJob.add_items_to_queue(item)
        end
      end
    end
    if ReindexingQueue.count>0 && !ReindexingJob.exists?
      Delayed::Job.enqueue(ReindexingJob.new, :priority=>DEFAULT_PRIORITY, :run_at=>1.seconds.from_now)
    end
  end

  def self.add_items_to_queue items, t=1.seconds.from_now, priority=DEFAULT_PRIORITY
    items = Array(items)

    disable_authorization_checks do
      items.uniq.each do |item|
        ReindexingQueue.create :item => item
      end
    end
    Delayed::Job.enqueue(ReindexingJob.new, :priority=>priority, :run_at=>t) unless ReindexingJob.exists?

  end

  def self.exists?
    Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ? ', @@my_yaml, nil, nil]).first != nil
  end
end
