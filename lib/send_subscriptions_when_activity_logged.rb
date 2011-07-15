ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    try_block{activity_loggable.send_immediate_subscriptions self}
  end
end