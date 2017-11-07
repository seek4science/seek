class ProgrammeSerializer < AvatarObjSerializer
  attributes :title, :description,
             :web_page,
             :funding_details

  attribute :tags, key: :funding_codes do
    serialize_annotations(object, context = 'funding_code')
  end

  has_many :people
  has_many :projects
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
end
