module TechnologyTypesHelper

  def link_to_technology_type assay
    parameters={}
    parameters[:uri]=assay.technology_type_uri
    parameters[:label] = assay.technology_type_label
    if assay.suggested_technology_type
      parameters[:suggested_type_id]=assay.suggested_technology_type.id
    end
    link_to parameters[:label],technology_types_path(parameters)
  end



  def child_technology_types_list_links children
    child_type_links children,"technology_type"
  end

end