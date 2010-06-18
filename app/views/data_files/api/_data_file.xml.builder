s_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "data_file",
core_xlink(data_file).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "DataFile" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>data_file}
  
end