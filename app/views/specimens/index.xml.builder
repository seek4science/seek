xml.instruct! :xml

xml.tag! "specimens",xlink_attributes(uri_for_collection("specimens", :params => params)),
xml_root_attributes,
         :resourceType => "Specimens" do

  render :partial=>"api/core_index_elements",:locals=>{:items=>@specimens,:parent_xml => xml}

end