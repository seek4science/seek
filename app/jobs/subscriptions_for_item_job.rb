# abstract superclass for common methods for handling subscription items, common to SetSubcriptionsForItemJob
# and RemoveSubscriptionForItemJob.
# perform_job methods is implemented in those subclasses
class SubscriptionsForItemJob < ApplicationJob
  queue_with_priority 1
end
