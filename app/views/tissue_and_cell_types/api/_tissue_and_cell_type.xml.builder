is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "tissue_and_cell_type",
core_xlink(tissue_and_cell_type).merge(is_root ? xml_root_attributes : {}) do

  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>tissue_and_cell_type}

end