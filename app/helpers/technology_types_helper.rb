module TechnologyTypesHelper

  def link_to_technology_type assay
    uri = assay.technology_type_uri
    label = assay.technology_type_label
    unless uri.nil?
      link_to label,technology_types_path(:uri=>uri,:label=>label)
    else
      label
    end
  end

  def parent_technology_types_list_links parents
    unless parents.empty?
      parents.collect do |par|
        link_to par.label,technology_types_path(uri: par.uri,label: par.label)
      end.join(" | ").html_safe
    else
      content_tag :span,"No parent terms",:class=>"none_text"
    end
  end

end
