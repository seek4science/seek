xml.instruct! :xml

xml.tag! "tissue_and_cell_types",xlink_attributes(uri_for_collection("tissue_and_cell_types", :params => params)),
xml_root_attributes,
         :resourceType => "Tissue_and_cell_types" do

  render :partial=>"api/core_index_elements",:locals=>{:items=>@tissue_and_cell_types,:parent_xml => xml}


end