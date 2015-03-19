class SetSubscriptionsForItemJob < SubscriptionsForItemJob

  def perform_job item
    item.set_default_subscriptions projects
  end

end