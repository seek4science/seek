ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    activity_loggable.send_immediate_subscription(self) if activity_loggable.respond_to? :send_immediate_subscription
  end
end