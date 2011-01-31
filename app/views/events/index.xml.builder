xml.instruct! :xml

xml.tag! "events",xlink_attributes(uri_for_collection("events", :params => params)),
xml_root_attributes,
         :resourceType => "Events" do

  render :partial=>"api/core_index_elements",:locals=>{:items=>@events,:parent_xml => xml}
end