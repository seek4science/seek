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
      Delayed::Job.find(:first,:conditions=>['handler = ? AND failed_at IS ?',SendPeriodicEmailsJob.new('#{frequency}').to_yaml,nil]) != nil
    end
    END_EVAL
  end

  def self.create_job frequency,t, priority=1
      Delayed::Job.enqueue(SendPeriodicEmailsJob.new(frequency),priority,t) unless send("#{frequency}_exists?")
  end

  def send_subscription_mails logs, frequency
    if Seek::Config.email_enabled
      #strip the logs down to those that are relevant
      logs.reject! do |log|
        !(log.activity_loggable.subscribable? && log.activity_loggable.subscribers_are_notified_of?(log.action))
      end

      Person.scoped(:include => [:notifiee_info,:subscriptions]).select{ |p| p.receive_notifications? }.each do |person|
        begin
          #get only the logs for items that are visible to this person
          logs_for_visible_items = logs.select{|log| log.activity_loggable.try(:can_view?,person.user)}

          #get the logs for this persons subscribable items, where the subscription has the correct frequency
          activity_logs = logs_for_visible_items.select do |log|
            !person.subscriptions.for_subscribable(log.activity_loggable).scoped(:include =>[:subscribable, :project_subscription]).select{ |s| s.frequency == frequency }.empty?
          end
          SubMailer.deliver_send_digest_subscription person, activity_logs, frequency unless activity_logs.blank?
        rescue Exception => e
          Delayed::Job.logger.error("Error sending subscription emails to person #{person.id} - #{e.message}")
        end
      end
    end
  end

  # puts the initial jobs on the queue for each period - daily, weekly, monthly - if they do not exist already
  # starting at midday
  def self.create_initial_jobs
    t=Time.now
    # start tomorrow if time now is later than midday
    t = t + 1.day if t > Time.local_time(t.year, t.month,t.day,12,00,00)
    SendPeriodicEmailsJob.create_job('daily', Time.local_time(t.year, t.month,t.day,12,00,00))   #at 12:00:00
    SendPeriodicEmailsJob.create_job('weekly', Time.local_time(t.year, t.month,t.day,12,05,00))  #at 12:05:00
    SendPeriodicEmailsJob.create_job('monthly', Time.local_time(t.year, t.month,t.day,12,10,00)) #at 12:10:00
  end
end
