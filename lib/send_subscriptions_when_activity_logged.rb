ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    activity_loggable.send_immediate_subscription(id) if activity_loggable.respond_to? :send_immediate_subscription and action!="show"
  end
end