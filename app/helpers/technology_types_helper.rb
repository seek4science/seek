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

end
