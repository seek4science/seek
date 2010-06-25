xml.instruct! :xml

xml.tag! "assay_types",xlink_attributes(uri_for_collection("assay_types", :params => params)), 
xml_root_attributes,
         :resourceType => "AssayTypes" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@assay_types,:parent_xml => xml}
  
  
end