# A job to create subscriptions for people who are members of this item's projects.
# Happens after a "subscribable" item is created.
class SetSubscriptionsForItemJob < SubscriptionsForItemJob
  def perform(subscribable, projects)
    disable_authorization_checks do
      subscribable.set_default_subscriptions(projects)
    end
  end
end
