module WorkflowsHelper
  # Get the MIME types in an array suitable for the use in forms for 'select' fields
  MIME_TYPE_OPTIONS = [['', '']] + Seek::MimeTypes::MIME_MAP.map do |mime_type, parameters|
    option = []
    option[0] = parameters[:name]
    default_extension = parameters[:extensions].first
    option[0] += " (.#{default_extension})" unless default_extension.blank?
    option[1] = mime_type
    option
  end.sort.uniq { |option| option[0] }.freeze

  def mime_type_options_for_select(selected)
    options_for_select(WorkflowsHelper::MIME_TYPE_OPTIONS, selected: selected)
  end

  def merge_workflow_filters(params, key, value)
    hash = { key => value }
    filters = params.merge(hash)
    filters.delete_if { |_k, v| v.nil? }
    filters
  end

  def workflow_filter(name, params, key, value)
    is_active = (params[key] == value.to_s) && !params[key].nil?

    link_to name, workflows_path(merge_workflow_filters(params, key, value)), class: (is_active ? 'active' : '')
  end
end
