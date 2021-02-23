class RemoveSubscriptionsForItemJob < SubscriptionsForItemJob
  def perform(subscribable, projects)
    disable_authorization_checks do
      subscribable.remove_subscriptions(projects)
    end
  end
end
