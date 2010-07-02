is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "investigation",
core_xlink(investigation).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>investigation}
  if (is_root)
    associated_resources_xml parent_xml,investigation
  end
  
end