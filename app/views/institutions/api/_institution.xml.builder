is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "institution",
core_xlink(institution).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Institution" do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>institution}  
  if (is_root)
    parent_xml.tag! "city",institution.city
    parent_xml.tag! "country",institution.country,core_xlink(institution.country)
    people_list_xml parent_xml, institution.people
    projects_list_xml parent_xml,institution.projects
  end
end