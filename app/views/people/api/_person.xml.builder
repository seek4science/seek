is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "person",
core_xlink(person).merge(is_root ? xml_root_attributes : {}) do    
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>person}
  parent_xml.tag! "first_name",person.first_name
  parent_xml.tag! "last_name",person.last_name
  
  if (is_root)                
    
    parent_xml.tag! "groups" do
      person.work_groups.each do |wg|        
        parent_xml.tag! "group",core_xlink(wg) do
          parent_xml.tag! "project",core_xlink(wg.project)
          parent_xml.tag! "institution",core_xlink(wg.institution)
        end
      end
    end
    
    parent_xml.tag! "tags" do
      person.tools.each do |tool|
        parent_xml.tag! "tag",tool.text,{:context=>:tool}
      end
      
      person.expertise.each do |tool|
        parent_xml.tag! "tag",tool.text,{:context=>:expertise}
      end
    end
    
    
    associated_resources_xml parent_xml,person
    
  end
  
end