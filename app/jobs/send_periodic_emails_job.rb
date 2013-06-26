class SendPeriodicEmailsJob < Struct.new(:frequency)
  DEFAULT_PRIORITY=3

  def perform
    next_run_at = Time.new
    logs = []
    begin
      if frequency == 'daily'
        next_run_at += 1.day
        logs = activity_logs_since Time.now.yesterday.utc
      elsif frequency == 'weekly'
        next_run_at += 1.week
        logs = activity_logs_since 7.days.ago
      elsif frequency == 'monthly'
        next_run_at += 1.month
        logs = activity_logs_since 1.month.ago
      end
      send_subscription_mails logs, frequency
      #add job for next period
      SendPeriodicEmailsJob.create_job(frequency, next_run_at, 1, true)
    rescue Exception=>e
      #add job for next period
      SendPeriodicEmailsJob.create_job(frequency, next_run_at, 1,true)
    end
  end

  Subscription::FREQUENCIES.drop(1).each do |frequency|
    eval <<-END_EVAL
    def self.#{frequency}_exists?
      exists? '#{frequency}'
    end
    END_EVAL
  end

  def self.exists? frequency, ignore_locked=false
    if ignore_locked
      Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ?',SendPeriodicEmailsJob.new("#{frequency}").to_yaml,nil,nil]).first != nil
    else
      Delayed::Job.where(['handler = ? AND failed_at IS ?',SendPeriodicEmailsJob.new("#{frequency}").to_yaml,nil]).first != nil
    end

  end


  def self.create_job frequency,t, priority=DEFAULT_PRIORITY, ignore_locked=false
      Delayed::Job.enqueue(SendPeriodicEmailsJob.new(frequency),:priority=>priority,:run_at=>t) unless exists?(frequency,ignore_locked)
  end

  def send_subscription_mails logs, frequency
    if Seek::Config.email_enabled
      #strip the logs down to those that are relevant
      logs.reject! do |log|
        log.activity_loggable.nil? || !log.activity_loggable.subscribable?
      end

      #limit to only the people subscribed to the items logged, and those that are set to receive notifications
      people = people_subscribed_to_logged_items logs
      people.reject!{|person| !person.receive_notifications?}

      people.each do |person|
        begin
          #get only the logs for items that are visible to this person
          logs_for_visible_items = logs.select{|log| log.activity_loggable.try(:can_view?,person.user)}

          #get the logs for this persons subscribable items, where the subscription has the correct frequency
          activity_logs = logs_for_visible_items.select do |log|
            !person.subscriptions.for_subscribable(log.activity_loggable).select{ |s| s.frequency == frequency }.empty?
          end
          SubMailer.send_digest_subscription(person, activity_logs, frequency).deliver unless activity_logs.blank?
        rescue Exception => e
          Delayed::Job.logger.error("Error sending subscription emails to person #{person.id} - #{e.message}")
        end
      end
    end
  end

  #returns an enumaration of the people subscribed to the items in the logs
  def people_subscribed_to_logged_items logs
    items = logs.collect{|log| log.activity_loggable}.uniq
    items.collect do |item|
      subscriptions = Subscription.find_all_by_subscribable_type_and_subscribable_id(item.class.name,item.id)
      subscriptions.collect{|sub| sub.person}
    end.flatten.compact.uniq
  end

  def activity_logs_since time_point
    ActivityLog.where(['created_at>=? and action in (?) and controller_name!=?', time_point, ['create', 'update'], 'sessions'])
  end

  # puts the initial jobs on the queue for each period - daily, weekly, monthly - if they do not exist already
  # starting at midday
  def self.create_initial_jobs
    t=Time.now
    # start tomorrow if time now is later than midday
    t = t + 1.day if t > Time.local_time(t.year, t.month,t.day,12,00,00)
    #at 12:00:00
    SendPeriodicEmailsJob.create_job('daily', Time.local_time(t.year, t.month,t.day,12,00,00)) if !SendPeriodicEmailsJob.exists?('daily')
    #at 12:05:00
    SendPeriodicEmailsJob.create_job('weekly', Time.local_time(t.year, t.month,t.day,12,05,00)) if !SendPeriodicEmailsJob.exists?('weekly')
    #at 12:10:00
    SendPeriodicEmailsJob.create_job('monthly', Time.local_time(t.year, t.month,t.day,12,10,00)) if !SendPeriodicEmailsJob.exists?('monthly')
  end
end
