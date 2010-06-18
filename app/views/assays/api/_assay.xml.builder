is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "assay",
xlink_attributes(uri_for_object(assay), :title => xlink_title(assay)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Assay" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>assay}
  parent_xml.tag! "assay_class",assay.assay_class.title,xlink_attributes(uri_for_object(assay.assay_class),:resourceType => "AssayClass")
  parent_xml.tag! "assay_type",assay.assay_type.title,xlink_attributes(uri_for_object(assay.assay_type),:resourceType => "AssayType")
  unless assay.is_modelling? 
    parent_xml.tag! "technology_type",assay.technology_type.title,xlink_attributes(uri_for_object(assay.technology_type),:resourceType => "TechnologyType")
  end
  
end