xml.instruct! :xml

xml.tag! "people",xlink_attributes(uri_for_collection("people", :params => params)), 
xml_root_attributes,
         :resourceType => "People" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@people,:parent_xml => xml}
    
end