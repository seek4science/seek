is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "assay",
core_xlink(assay).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Assay" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>assay}
  parent_xml.tag! "assay_class",assay.assay_class.title,core_xlink(assay.assay_class)
  parent_xml.tag! "assay_type",assay.assay_type.title,core_xlink(assay.assay_type)
  unless assay.is_modelling? 
    parent_xml.tag! "technology_type",assay.technology_type.title,core_xlink(assay.technology_type)
  end
  if (is_root)
    associated_resources_xml parent_xml,assay
  end
  
end