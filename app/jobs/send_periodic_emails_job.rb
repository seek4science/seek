class SendPeriodicEmailsJob < Struct.new(:frequency)

  @@my_yaml = SendPeriodicEmailsJob.new.to_yaml

  def perform
    next_run_at = Time.new
    if frequency == 'daily'
      send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at=?', Date.yesterday]), 'daily'
      next_run_at += 1.day
    elsif frequency == 'weekly'
      send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 7.days.ago]), 'weekly'
      next_run_at += 1.week
    elsif frequency == 'weekly'
      send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 30.days.ago]), 'monthly'
      next_run_at += 1.month
    end
     #add job for next period
    SendPeriodicEmailsJob.create_job(frequency, next_run_at, 1)
  end

  def self.exists?
    Delayed::Job.find(:first,:conditions=>['handler = ? AND locked_at IS ? AND failed_at IS ?',@@my_yaml,nil,nil]) != nil
  end

  def self.create_job frequency,t, priority=1
      Delayed::Job.enqueue(SendPeriodicEmailsJob.new(frequency),priority,t) unless exists?
  end

  def send_subscription_mails logs, frequency
     Person.scoped(:include => :subscriptions).select{|p|p.receive_notifications?}.each do |person|
       activity_logs = person.subscriptions.scoped(:include => :subscribable).select{|s|s.frequency == frequency}.collect do |sub|
          logs.select{|log|log.activity_loggable.try(:can_view?, person.user) and log.activity_loggable.subscribable? and log.activity_loggable.subscribers_are_notified_of?(log.action) and log.activity_loggable == sub.subscribable}
       end.flatten(1)
       SubMailer.deliver_send_digest_subscription person, activity_logs unless activity_logs.blank?
     end
   end
end
