ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    if Seek::Config.email_enabled && activity_loggable.subscribers_are_notified_of?(activity_log.action)
      SubscriptionJob.add_items_to_queue self.id
    end
  end
end