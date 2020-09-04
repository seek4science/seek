class ProjectLeavingJob < SeekJob
  def perform(person, project = nil)
    if project
      AuthLookupUpdateQueue.enqueue(([person] + project.asset_housekeepers).compact.uniq)
    end
  end
end
