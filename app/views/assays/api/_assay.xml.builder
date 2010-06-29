is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "assay",
core_xlink(assay).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Assay" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>assay}
  parent_xml.tag! "assay_class",core_xlink(assay.assay_class)
  parent_xml.tag! "assay_type",core_xlink(assay.assay_type)
  unless assay.is_modelling? 
    parent_xml.tag! "technology_type",assay.technology_type.title,core_xlink(assay.technology_type)
  end
  if (is_root)    
    parent_xml.tag! "assay_organisms" do      
      assay.assay_organisms.each do |ao| 
        parent_xml.tag! "assay_organism" do
          api_partial parent_xml,ao.organism
          api_partial parent_xml,ao.strain if ao.strain
          parent_xml.tag! "culture_growth",ao.culture_growth_type.title,core_xlink(ao.culture_growth_type) if ao.culture_growth_type          
        end      
      end      
    end
    
    if assay.is_modelling? 
      assay_data_relationships_xml parent_xml,assay
    end
    
    associated_resources_xml parent_xml,assay
    
  end
  
end