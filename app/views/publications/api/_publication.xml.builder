is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "publication",
core_xlink(publication).merge(is_root ? xml_root_attributes : {}) do

  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>publication}
  if (is_root)
        parent_xml.tag! "creators" do
          publication.publication_authors.each do |pa|
              if pa.person
                    api_partial parent_xml, pa.person
              else
                parent_xml.tag! "person" do
                  parent_xml.tag! "dc:title",  "#{pa.first_name} #{pa.last_name}"
                  parent_xml.tag! "first_name",pa.first_name
                  parent_xml.tag! "last_name",pa.last_name
                end
              end
          end
        end

    publication.doi.blank? ? parent_xml.tag!("doi",{"xsi:nil"=>true}) : parent_xml.tag!("doi",publication.doi)
    publication.pubmed_id.blank? ? parent_xml.tag!("pubmed_id",{"xsi:nil"=>true}) : parent_xml.tag!("pubmed_id",publication.pubmed_id)
    parent_xml.tag! "abstract",publication.abstract
    parent_xml.tag! "journal",publication.journal
    parent_xml.tag! "citation",publication.citation
    parent_xml.tag! "published_date",publication.published_date
    associated_resources_xml parent_xml,publication
  end
end