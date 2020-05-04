xml.instruct! :xml

xml.tag! "human_diseases",xlink_attributes(uri_for_collection("human_diseases", :params => params)), 
xml_root_attributes,
         :resourceType => "Human Diseases" do
  
  render :partial=>"api/core_index_elements",:locals=>{:items=>@human_diseases,:parent_xml => xml}
  
  
end
