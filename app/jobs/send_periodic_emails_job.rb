class SendPeriodicEmailsJob < Struct.new(:frequency)

  def perform
    next_run_at = Time.new
    begin
      if frequency == 'daily'
        send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', Time.now.yesterday.utc]), 'daily'
        next_run_at += 1.day
      elsif frequency == 'weekly'
        send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 7.days.ago]), 'weekly'
        next_run_at += 1.week
      elsif frequency == 'monthly'
        send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 30.days.ago]), 'monthly'
        next_run_at += 1.month
      end
      #add job for next period
      SendPeriodicEmailsJob.create_job(frequency, next_run_at, 1)
    rescue Exception=>e
      #add job for next period
      SendPeriodicEmailsJob.create_job(frequency, next_run_at, 1)
    end
  end

  Subscription::FREQUENCIES.drop(1).each do |frequency|
    eval <<-END_EVAL
    def self.#{frequency}_exists?
      Delayed::Job.find(:first,:conditions=>['handler = ? AND locked_at IS ? AND failed_at IS ?',SendPeriodicEmailsJob.new('#{frequency}').to_yaml,nil,nil]) != nil
    end
    END_EVAL
  end

  def self.create_job frequency,t, priority=1
      Delayed::Job.enqueue(SendPeriodicEmailsJob.new(frequency),priority,t) unless send("#{frequency}_exists?")
  end

  def send_subscription_mails logs, frequency
     Person.scoped(:include => :subscriptions).select{|p|p.receive_notifications?}.each do |person|
       activity_logs = person.subscriptions.scoped(:include => :subscribable).select{|s|s.frequency == frequency}.collect do |sub|
          logs.select{|log|log.activity_loggable.try(:can_view?, person.user) and log.activity_loggable.subscribable? and log.activity_loggable.subscribers_are_notified_of?(log.action) and log.activity_loggable == sub.subscribable}
       end.flatten(1)
       SubMailer.deliver_send_digest_subscription person, activity_logs, frequency unless activity_logs.blank?
     end
   end
end
