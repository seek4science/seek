xml.instruct! :xml

xml.tag! "publications",xlink_attributes(uri_for_collection("publications", :params => params)), 
xml_root_attributes,
         :resourceType => "Publications" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@publications,:parent_xml => xml}
    
end