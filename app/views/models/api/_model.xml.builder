s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "model",
xlink_attributes(uri_for_object(model), :title => xlink_title(model)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Model" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>model}
  
end