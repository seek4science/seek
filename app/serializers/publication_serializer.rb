class PublicationSerializer < BaseSerializer
  attributes :id, :title,
             :journal, :published_date,
             :doi, :pubmed_id,
             :description, :abstract, :citation

  has_many :associated do
    associated_resources(object)
  end
end
