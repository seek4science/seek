class RemoveSubscriptionsForItemJob < SubscriptionsForItemJob
  def perform_job(item)
    disable_authorization_checks do
      item.remove_subscriptions projects
    end
  end
end
