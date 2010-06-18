s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "investigation",
xlink_attributes(uri_for_object(investigation), :title => xlink_title(investigation)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Investigation" do
  
  core_xml parent_xml,investigation
  
  
end