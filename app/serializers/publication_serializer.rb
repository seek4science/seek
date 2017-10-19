class PublicationSerializer < BaseSerializer
  attributes :title, #:publication_authors,
             :journal, :published_date,
             :doi, :pubmed_id,
             :abstract, :citation # , :persons --> creators?
  attribute :link_to_pub do
    if :pubmed_id
      'https://www.ncbi.nlm.nih.gov/pubmed/' + object.pubmed_id.to_s
    elsif :doi
      'http://dx.doi.org/' + object.doi.to_s
    else
      ''
    end
  end

  attribute :authors do
    if object.publication_author_names.blank?
      []
    else
      object.publication_author_names
      end
  end

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :publications
  has_many :presentations
  has_many :events
end
