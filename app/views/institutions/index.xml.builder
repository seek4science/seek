xml.instruct! :xml

xml.tag! "institutions",xlink_attributes(uri_for_collection("institutions", :params => params)), 
xml_root_attributes,
         :resourceType => "Institutions" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@institutions,:parent_xml => xml}
    
end