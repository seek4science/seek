class InvestigationSerializer < PCSSerializer
  attributes :title, :description, :other_creators

  has_many :people
  has_many :projects
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :documents
end
