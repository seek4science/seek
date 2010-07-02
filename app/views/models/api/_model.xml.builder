is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "model",
core_xlink(model).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>model}
  if (is_root)
    parent_xml.tag! "model_type",model.model_type.title,core_xlink(model.model_type) unless model.model_type.nil?
    parent_xml.tag! "model_format",model.model_format.title,core_xlink(model.model_format) unless model.model_format.nil?
    parent_xml.tag! "environment",model.recommended_environment.title,core_xlink(model.recommended_environment) unless model.recommended_environment.nil?
    associated_resources_xml parent_xml,model     
  end
end