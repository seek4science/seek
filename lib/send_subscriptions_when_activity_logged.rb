ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    if Seek::Config.email_enabled
      activity_loggable.send_immediate_subscriptions(self) if activity_loggable.respond_to :send_immediate_subscriptions
    end
  end
end