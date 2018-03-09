class SetSubscriptionsForItemJob < SubscriptionsForItemJob
  def perform_job(item)
    disable_authorization_checks do
      item.set_default_subscriptions projects
    end
  end
end
