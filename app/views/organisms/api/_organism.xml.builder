is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "organism",
core_xlink(organism).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>organism}  
  if (is_root)    
    parent_xml.tag! "strains" do
      api_partial_collection parent_xml,organism.strains     
    end
    associated_resources_xml parent_xml,organism
  end
end