# A job to subscribe someone to all items in a project.
# Happens when a new "ProjectSubscription" is created.
class ProjectSubscriptionJob < ApplicationJob
  queue_with_priority 2

  def perform(project_subscription)
    project_subscription.subscribe_to_all_in_project
  end
end
