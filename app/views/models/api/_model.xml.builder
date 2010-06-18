s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "model",
xlink_attributes(uri_for_object(model), :title => xlink_title(model)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Model" do
  
  core_xml parent_xml,model  
  
end