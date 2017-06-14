class ProjectLeavingJob < SeekJob
  attr_reader :person_id
  attr_reader :project_id

  def initialize(person, project)
    @person_id = person.try(:id)
    @project_id = project.try(:id)
  end

  def perform_job(item)
    if item[:project] && Seek::Config.auth_lookup_enabled
      AuthLookupUpdateJob.new.add_items_to_queue(([item[:person]] + item[:project].asset_housekeepers).compact.uniq)
    end
  end

  def gather_items
    [{ person: Person.find_by_id(person_id), project: Project.find_by_id(project_id) }]
  end
end
