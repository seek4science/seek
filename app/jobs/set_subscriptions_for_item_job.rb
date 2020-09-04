class SetSubscriptionsForItemJob < SubscriptionsForItemJob
  def perform(subscribable, projects)
    disable_authorization_checks do
      subscribable.set_default_subscriptions(projects)
    end
  end
end
