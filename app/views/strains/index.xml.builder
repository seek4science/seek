xml.instruct! :xml

xml.tag! "strains",xlink_attributes(uri_for_collection("strains", :params => params)), 
xml_root_attributes,
         :resourceType => "Strains" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@strains,:parent_xml => xml}
  
  
end