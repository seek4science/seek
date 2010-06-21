is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "publication",
core_xlink(publication).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Publication" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>publication} 
  if (is_root)
    associated_resources_xml parent_xml,publication
  end
end