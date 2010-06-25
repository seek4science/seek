is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "assay_type",
core_xlink(assay_type).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "AssayType" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>assay_type}
  
  if (is_root)
    parent_child_elements parent_xml,assay_type
  end
  
end

