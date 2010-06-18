xml.instruct! :xml

xml.tag! "assays",xlink_attributes(uri_for_collection("assays", :params => params)), 
xml_root_attributes,
         :resourceType => "Assays" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@assays,:parent_xml => xml}
  
  
end