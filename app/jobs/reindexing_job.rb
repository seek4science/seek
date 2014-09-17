class ReindexingJob

  @@my_yaml = ReindexingJob.new.to_yaml

  BATCHSIZE=10
  DEFAULT_PRIORITY=2
  TIMELIMIT = 15.minutes

  def perform
    todo = ReindexingQueue.order("id ASC").limit(BATCHSIZE).collect do |queued|
      todo = queued.item
      queued.destroy
      todo
    end
    if Seek::Config.solr_enabled
      todo.uniq.compact.each do |item|
        begin
          Timeout::timeout(TIMELIMIT) do
            item.solr_index!
          end
        rescue Exception => e
          Rails.logger.error(e)
          if Seek::Config.exception_notification_enabled
            ExceptionNotifier.notify_exception(e,:data=>{:item_type=>item.class.name,:item_id=>item.try(:id),:message=>'Problem reindexing'})
          end
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
