xml.instruct! :xml

xml.tag! "data_files",xlink_attributes(uri_for_collection("data_files", :params => params)), 
xml_root_attributes,
         :resourceType => "DataFiles" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@data_files,:parent_xml => xml}
  
  
end