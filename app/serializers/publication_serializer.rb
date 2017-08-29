class PublicationSerializer < BaseSerializer
  attributes :title, #:publication_authors,
             :journal, :published_date,
             :doi, :pubmed_id,
             :abstract, :citation #, :persons --> creators?
  attribute :link_to_pub do
    if :pubmed_id
      "https://www.ncbi.nlm.nih.gov/pubmed/"+object.pubmed_id.to_s
    elsif :doi
      "http://dx.doi.org/"+object.doi.to_s
    else
      ""
    end
  end
  has_many :publication_authors, include_data:true
end
