class SendImmediateEmailsJob < SeekEmailJob
  DEFAULT_PRIORITY = 3

  attr_reader :activity_log_id

  def initialize(activity_log_id)
    @activity_log_id = activity_log_id
  end

  def perform_job(activity_log)
    activity_loggable = activity_log.activity_loggable
    activity_loggable.send_immediate_subscriptions(activity_log) if activity_loggable.respond_to? :send_immediate_subscriptions
  end

  def gather_items
    [ActivityLog.find_by_id(activity_log_id)].compact
  end

  def default_priority
    3
  end

  def allow_duplicate_jobs?
    false
  end
end
