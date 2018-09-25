module WorkflowsHelper
  def authorised_Workflows(projects = nil)
    authorised_assets(Workflow, projects)
  end
end
