class ProjectLeavingJob < ApplicationJob
  def perform(person, project)
    AuthLookupUpdateQueue.enqueue(([person] + project.asset_housekeepers).compact.uniq) if project
  end
end
