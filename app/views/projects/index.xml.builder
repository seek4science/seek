xml.instruct! :xml

xml.tag! "projects",xlink_attributes(uri_for_collection("projects", :params => params)), 
xml_root_attributes,
         :resourceType => "Projects" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@projects,:parent_xml => xml}
    
end