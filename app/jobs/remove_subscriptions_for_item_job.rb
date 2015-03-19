class RemoveSubscriptionsForItemJob < SubscriptionsForItemJob
  def perform_job(item)
    item.remove_subscriptions projects
  end
end
