xml.instruct! :xml

xml.tag! "models",xlink_attributes(uri_for_collection("models", :params => params)), 
xml_root_attributes,
         :resourceType => "Models" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@models,:parent_xml => xml}
  
  
end