module WorkflowsHelper
  def authorised_Workflows(projects = nil)
    authorised_assets(Workflow, projects)
  end

  def status_css_class(execution_item)
    "status-" + execution_item.status_name
  end
end
