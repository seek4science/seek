class ProjectSerializer < AvatarObjSerializer
  # class ProjectSerializer < ActiveModel::Serializer
  attributes :title, :description,
             :web_page, :wiki_page
  has_many :organisms,  include_data: true

  has_many :people
  has_many :institutions
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :presentations
  has_many :events
  has_many :strains
  has_many :samples
end
