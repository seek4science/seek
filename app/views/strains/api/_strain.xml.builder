is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "strain",
core_xlink(strain).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>strain}  
  
end