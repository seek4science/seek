xml.instruct! :xml

xml.tag! "sops",xlink_attributes(uri_for_collection("sops", :params => params)), 
xml_root_attributes,
         :resourceType => "Sops" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@sops,:parent_xml => xml}
  
  
end