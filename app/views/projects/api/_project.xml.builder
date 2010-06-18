s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "project",
xlink_attributes(uri_for_object(project), :title => xlink_title(project)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Project" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>project}
  
end