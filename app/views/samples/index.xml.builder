xml.instruct! :xml

xml.tag! "samples",xlink_attributes(uri_for_collection("samples", :params => params)),
xml_root_attributes,
         :resourceType => "Samples" do

  render :partial=>"api/core_index_elements",:locals=>{:items=>@samples,:parent_xml => xml}

end