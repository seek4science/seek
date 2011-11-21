ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    if Seek::Config.email_enabled
      try_block{activity_loggable.send_immediate_subscriptions(self)}
    end
  end
end