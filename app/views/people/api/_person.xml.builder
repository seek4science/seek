s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "person",
xlink_attributes(uri_for_object(person), :title => xlink_title(person)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Person" do
  
  core_xml parent_xml,person
  
end