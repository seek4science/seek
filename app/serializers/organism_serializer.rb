class OrganismSerializer < BaseSerializer
  attributes :title, :concept_uri, :ontology_id

  has_many :projects
  has_many :assays
  has_many :models
  has_many :strains
  has_many :samples

  def strains
    object.strains
  end
end
