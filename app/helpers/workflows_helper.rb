module WorkflowsHelper
  def authorised_Workflows(projects = nil)
    authorised_assets(Workflow, projects)
  end

  def status_css_class(execution_item)
    "status-" + execution_item.status_name
  end

  def galaxy_step_status(step_json)
    return unless step_json
    begin
      step_json = JSON.parse(step_json)
      values = step_json.values
      n_ok = values.count("ok")
      n_running = values.count("running")
      n_queued = values.count{|v| v == "new" || v=="queued"}
      content_tag(:span,n_queued,class:'step_queued step_status',title:"Queued") +
          content_tag(:span,n_running,class:'step_running step_status',title:"Running") +
          content_tag(:span,n_ok,class:'step_finished step_status',title:"Ok")

    rescue
    end
  end
end
