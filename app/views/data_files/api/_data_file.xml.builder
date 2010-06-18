s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "data_file",
xlink_attributes(uri_for_object(data_file), :title => xlink_title(data_file)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "DataFile" do
  
  core_xml parent_xml,data_file
  
  
end