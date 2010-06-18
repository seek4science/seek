s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "study",
xlink_attributes(uri_for_object(study), :title => xlink_title(study)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Study" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>study}
  
  
end