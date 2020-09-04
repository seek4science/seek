class SendPeriodicEmailsJob < ApplicationJob
  DELAYS = { 'daily' => 1.day, 'weekly' => 1.week, 'monthly' => 1.month }.freeze

  def perform
    return unless Seek::Config.email_enabled
    logs = find_relevant_logs
    subscribed_people(logs).each do |person|
      begin
        collect_and_deliver_to_person(logs, person)
      rescue Exception => e
        Delayed::Job.logger.error("Error sending subscription emails to person #{person.id} - #{e.message}")
      end
    end
  end

  def collect_and_deliver_to_person(logs, person)
    activity_logs = collect_relevant_logs_for_person(logs, person)
    SubMailer.send_digest_subscription(person, activity_logs, frequency).deliver_later if activity_logs.any?
  end

  def collect_relevant_logs_for_person(logs, person)
    # get only the logs for items that are visible to this person
    logs_for_visible_items = logs.select { |log| log.activity_loggable.try(:can_view?, person.user) }

    # get the logs for this persons subscribable items, where the subscription has the correct frequency
    logs_for_visible_items.select do |log|
      person.subscriptions.for_subscribable(log.activity_loggable).any? do |subscription|
        subscription.frequency == frequency
      end
    end
  end

  # limit to only the people subscribed to the items logged, and those that are set to receive notifications and are project members
  def subscribed_people(logs)
    people = people_subscribed_to_logged_items logs
    people.select(&:receive_notifications?)
  end

  # returns an enumaration of the people subscribed to the items in the logs
  def people_subscribed_to_logged_items(logs)
    items = logs.collect(&:activity_loggable).uniq.compact
    items.collect do |item|
      Subscription.where(subscribable_type: item.class.name, subscribable_id: item.id).collect(&:person)
    end.flatten.compact.uniq
  end

  def activity_logs_since(time_point)
    ActivityLog.where(['created_at >= ? and action in (?) and controller_name != ?', time_point, %w[create update], 'sessions'])
  end

  def find_relevant_logs
    # strip the logs down to those that are relevant
    activity_logs_since(delay_for_frequency.ago).to_a.select do |log|
      log.activity_loggable.try(:subscribable?)
    end
  end
end
