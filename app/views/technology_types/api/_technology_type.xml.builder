is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "technology_type",
core_xlink(technology_type).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "TechnologyType" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>technology_type}
  
end