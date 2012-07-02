class SendPeriodicEmailsJob < Struct.new(:frequency)

  def perform
    next_run_at = Time.new
    begin
      if frequency == 'daily'
        next_run_at += 1.day
        send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', Time.now.yesterday.utc]), 'daily'
      elsif frequency == 'weekly'
        next_run_at += 1.week
        send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 7.days.ago]), 'weekly'
      elsif frequency == 'monthly'
        next_run_at += 1.month
        send_subscription_mails ActivityLog.scoped(:include => :activity_loggable, :conditions => ['created_at>=?', 1.month.ago]), 'monthly'
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
    if Seek::Config.email_enabled
      Person.scoped(:include => :subscriptions).select { |p| p.receive_notifications? }.each do |person|
        begin
          activity_logs = person.subscriptions.scoped(:include => :subscribable).select { |s| s.frequency == frequency }.collect do |sub|
            logs.select do |log|
              log.activity_loggable.try(:can_view?, person.user) && log.activity_loggable.subscribable? && log.activity_loggable.subscribers_are_notified_of?(log.action) && log.activity_loggable == sub.subscribable
            end
          end.flatten(1)
          SubMailer.deliver_send_digest_subscription person, activity_logs, frequency unless activity_logs.blank?
        rescue Exception => e
          Delayed::Job.logger.error("Error sending subscription emails to person #{person.id} - #{e.message}")
        end
      end
    end
  end
end
