module TechnologyTypesHelper

  def link_to_technology_type assay
    #FIXME:duplicates assay type method
    parameters={}
    parameters[:uri]=assay.suggested_technology_type.try(:uri) || assay.technology_type_uri
    parameters[:label] = assay.technology_type_label
    link_to parameters[:label],technology_types_path(parameters)
  end

  def child_technology_types_list_links children
    child_type_links children,"technology_type"
  end

end