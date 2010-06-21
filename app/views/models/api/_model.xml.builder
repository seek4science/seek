is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "model",
core_xlink(model).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Model" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>model}
  if (is_root)
    associated_resources_xml parent_xml,model
  end
end