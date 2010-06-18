xml.instruct! :xml

xml.tag! "studies",xlink_attributes(uri_for_collection("studies", :params => params)), 
xml_root_attributes,
         :resourceType => "Studies" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@studies,:parent_xml => xml}
  
end