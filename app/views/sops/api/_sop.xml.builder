s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "sop",
xlink_attributes(uri_for_object(sop), :title => xlink_title(sop)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Sop" do
  
  core_xml parent_xml,sop
  
  
end