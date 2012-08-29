xml.instruct! :xml

xml.tag! "presentations",xlink_attributes(uri_for_collection("presentations", :params => params)),
xml_root_attributes,
         :resourceType => "Presentations" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@presentations,:parent_xml => xml}
  
  
end