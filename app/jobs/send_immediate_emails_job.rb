class SendImmediateEmailsJob < SeekEmailJob
  queue_with_priority 3

  def perform(activity_log)
    activity_loggable = activity_log.activity_loggable
    activity_loggable.send_immediate_subscriptions(activity_log) if activity_loggable.respond_to? :send_immediate_subscriptions
  end

  # Add a short delay so that SetSubscriptionsForItemJob has time to finish and the subscriptions are in place.
  def default_delay
    10.seconds
  end
end
