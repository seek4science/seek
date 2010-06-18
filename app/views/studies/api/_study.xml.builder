s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "study",
xlink_attributes(uri_for_object(study), :title => xlink_title(study)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Study" do
  
  core_xml parent_xml,study
  
  
end