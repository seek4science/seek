ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    activity_loggable.try :send_immediate_subscriptions, self
  end
end