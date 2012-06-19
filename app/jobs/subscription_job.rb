class SubscriptionJob

  @@my_yaml = SubscriptionJob.new.to_yaml

  BATCHSIZE=3

  def perform
      todo = SubscriptionQueue.all(:limit=>BATCHSIZE,:order=>:id).collect do |queued|
        todo = queued.item
        queued.destroy
        todo
      end
      todo.uniq.each do |item|
        begin
          activity_log = item.activity_log
          activity_loggable = activity_log.activity_loggable
          activity_loggable.send_immediate_subscriptions(activity_log) if activity_loggable.respond_to? :send_immediate_subscriptions
        rescue Exception=>e
          SubscriptionQueue.add_items_to_queue(item, 3, 1.seconds.from_now)
        end
      end

      if SubscriptionQueue.count>0 && !SubscriptionJob.exists?
        Delayed::Job.enqueue(SubscriptionJob.new,3,1.seconds.from_now)
      end
  end

    def self.add_items_to_queue items, priority = 3, t=20.minutes.from_now
      items = Array(items)
      disable_authorization_checks do
        items.uniq.each do |item|
          SubscriptionQueue.create :activity_log_id=>item
        end
      end
      Delayed::Job.enqueue(SubscriptionJob.new, priority, t) unless SubscriptionJob.exists?
    end

    def self.exists?
      Delayed::Job.find(:first,:conditions=>['handler = ? AND locked_at IS ? AND failed_at IS ?',@@my_yaml,nil,nil]) != nil
    end
  end