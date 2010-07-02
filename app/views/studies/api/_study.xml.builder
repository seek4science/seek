is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "study",
core_xlink(study).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>study}
  if (is_root)
    associated_resources_xml parent_xml,study
  end
  
end