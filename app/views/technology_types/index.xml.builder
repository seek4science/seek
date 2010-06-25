xml.instruct! :xml

xml.tag! "technology_types",xlink_attributes(uri_for_collection("technology_types", :params => params)), 
xml_root_attributes,
         :resourceType => "TechnologyTypes" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@technology_types,:parent_xml => xml}
    
end