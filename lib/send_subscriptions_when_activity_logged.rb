ActivityLog.class_eval do
  after_create :send_notification

  def send_notification
    if Seek::Config.email_enabled
      SubscriptionJob.add_items_to_queue self.id
    end
  end
end