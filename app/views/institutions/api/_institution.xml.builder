s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "institution",
xlink_attributes(uri_for_object(institution), :title => xlink_title(institution)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Institution" do
  
  core_xml parent_xml,institution
  
end