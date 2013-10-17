module WorkflowsHelper

  def merge_workflow_filters(params, key, value)
    hash = {key => value}
    filters = params.merge(hash)
    filters.delete_if {|k,v| v.nil?}
    filters
  end

  def workflow_filter(name, params, key, value)
    is_active = (params[key].to_i == value) && !params[key].nil?

    link_to name, workflows_path(merge_workflow_filters(params, key, value)), :class => (is_active ? 'active' : '')
  end

end