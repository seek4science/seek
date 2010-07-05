is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "model",
core_xlink(model).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>model}
  if (is_root)
    model.model_type.nil? ? parent_xml.tag!("model_type","",{"xsi:nil"=>true}) : parent_xml.tag!("model_type",model.model_type.title)
    model.model_format.nil? ? parent_xml.tag!("model_format","",{"xsi:nil"=>true}) : parent_xml.tag!("model_format",model.model_format.title)
    model.recommended_environment.nil? ? parent_xml.tag!("environment","",{"xsi:nil"=>true}) : parent_xml.tag!("environment",model.recommended_environment.title)

    associated_resources_xml parent_xml,model     
  end
end