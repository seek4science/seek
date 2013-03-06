class SendImmediateEmailsJob < Struct.new(:activity_log_id)
  DEFAULT_PRIORITY=3

  def perform
    activity_log = ActivityLog.find_by_id(activity_log_id)
    if activity_log
      activity_loggable = activity_log.activity_loggable
      activity_loggable.send_immediate_subscriptions(activity_log) if activity_loggable.respond_to? :send_immediate_subscriptions
    end
  end

  def self.exists? activity_log_id
    Delayed::Job.find(:first, :conditions => ['handler = ? AND locked_at IS ? AND failed_at IS ?', SendImmediateEmailsJob.new(activity_log_id).to_yaml, nil, nil]) != nil
  end

  def self.create_job activity_log_id, t=30.seconds.from_now, priority=DEFAULT_PRIORITY
    Delayed::Job.enqueue(SendImmediateEmailsJob.new(activity_log_id), priority, t) unless exists? activity_log_id
  end
end