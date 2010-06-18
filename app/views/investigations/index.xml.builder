xml.instruct! :xml

xml.tag! "investigations",xlink_attributes(uri_for_collection("investigations", :params => params)), 
xml_root_attributes,
         :resourceType => "Investigations" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@investigations,:parent_xml => xml}
  
  
end