s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "institution",
xlink_attributes(uri_for_object(institution), :title => xlink_title(institution)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Institution" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>institution}  
end