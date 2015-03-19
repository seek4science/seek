class SendImmediateEmailsJob < SeekJob
  DEFAULT_PRIORITY = 3

  attr_reader :activity_log_id

  def before(_job)
    # make sure the SMTP,site_base_host configuration is in sync with current SEEK settings
    Seek::Config.smtp_propagate
    Seek::Config.site_base_host_propagate
  end

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
