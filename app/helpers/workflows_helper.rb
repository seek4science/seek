module WorkflowsHelper

  # Get the MIME types in an array suitable for the use in forms for 'select' fields
  mime_types_names_list = Seek::MimeTypes::MIME_MAP.map do |key, value|
    s = "#{value[:name]}"
    s += " (.#{value[:extensions].first})" unless value[:extensions].first.blank?
    s
  end.uniq.sort

  $mime_types_list = [['', '']]
  mime_types_names_list.each do |name|
    $mime_types_list << [ name, (Seek::MimeTypes::MIME_MAP.map{ |key, value|  key if value[:name] == name }.compact)[0] ]
  end


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