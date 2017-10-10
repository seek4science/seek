class ModelSerializer < ContributedResourceSerializer
  attributes :model_type, :model_format
  attribute :environment do
    object.recommended_environment
  end

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications

end

