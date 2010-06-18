s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "publication",
xlink_attributes(uri_for_object(publication), :title => xlink_title(publication)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Publication" do
  
  core_xml parent_xml,publication  
  
end