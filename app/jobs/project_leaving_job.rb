class ProjectLeavingJob < ApplicationJob
  def perform(group_membership)
    project = group_membership.project
    person = group_membership.person
    return if project.nil? || person.nil?
    AuthLookupUpdateQueue.enqueue(([person] + project.asset_housekeepers).compact.uniq)
    group_membership.update_column(:has_left, true)
  end

  # jobs created if due, triggered by the scheduler.rb
  def self.queue_timed_jobs
    GroupMembership.due_to_expire.find_each do |group_membership|
      ProjectLeavingJob.perform_later(group_membership)
    end
  end
end
