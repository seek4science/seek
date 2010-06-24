xml.instruct! :xml

xml.tag! "organisms",xlink_attributes(uri_for_collection("organisms", :params => params)), 
xml_root_attributes,
         :resourceType => "Organisms" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@organisms,:parent_xml => xml}
  
  
end