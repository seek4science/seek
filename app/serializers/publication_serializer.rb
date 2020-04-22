class PublicationSerializer < PCSSerializer
  include PublicationsHelper
  attributes :title, #:publication_authors,
             :journal, :published_date,
             :doi, :pubmed_id,
             :abstract, :citation,:editor, :booktitle, :publisher, :url
  attribute :link_to_pub do
    if !object.pubmed_id.blank?
      'https://www.ncbi.nlm.nih.gov/pubmed/' + object.pubmed_id.to_s
    elsif !object.doi.blank?
      'https://doi.org/' + object.doi.to_s
    elsif !object.url.blank?
      object.url.to_s
    else
      nil
    end
  end

  attribute :publication_type do
    PublicationType.find(object.publication_type_id).title
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
