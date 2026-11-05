class PeriodicSubscriptionEmailJob < ApplicationJob
  DELAYS = { 'daily' => 1.day, 'weekly' => 1.week, 'monthly' => 1.month }.freeze

  def perform(frequency)
    return unless Seek::Config.email_enabled

    since = DELAYS[frequency].ago
    activity_logs = gather_logs(since)
    group_by_subscriber(activity_logs, frequency).each do |person, logs|
      begin
        SubMailer.send_digest_subscription(person, logs, frequency).deliver_later
      rescue Exception => e
        raise("Error sending subscription emails to person #{person.id} - #{e.message}")
      end
    end
  end

  # Group the given set of ActivityLogs by the people subscribed to the `activity_loggable`,
  # ensuring they have permission to view.
  def group_by_subscriber(logs, frequency)
    group = {}

    logs.each do |log|
      resource = log.activity_loggable
      next unless resource # Skip resources that were destroyed
      log.reload # Load the full record from the ActivityLog table, since it was pared down by `SELECT` previously.
      subscribers(log).each do |person|
        # Check if the person can view the resource, and if they have a subscription for the given frequency.
        if resource.can_view?(person.user) &&
          # TODO: Allow this frequency check to be done in a DB query, then it can be done in the `subscribers` method.
          person.subscriptions.for_subscribable(resource).any? do |subscription|
            subscription.frequency == frequency
          end
          group[person] ||= []
          group[person] << log
        end
      end
    end

    group
  end

  # Get create/update activity logs for subscribable resources in the given period,
  # but limit to only the latest relevant log for each resource.
  def gather_logs(since)
    types = Seek::Util.persistent_classes.select(&:subscribable?).map(&:name)
    ActivityLog.
      where(activity_loggable_type: types, action: %w[create update]).
      where.not(controller_name: 'sessions').
      where('created_at >= ?', since).
      select(ActivityLog.arel_table[:id].maximum.as('id'), :activity_loggable_id, :activity_loggable_type).
      group([:activity_loggable_id, :activity_loggable_type])
  end

  # Get all the subscribers who should be notified about the given log event
  def subscribers(log)
    Person.notifiable.joins(:subscriptions).where(subscriptions: {
      subscribable_type: log.activity_loggable_type,
      subscribable_id: log.activity_loggable_id })
  end
end
