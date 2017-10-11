class ModelSerializer < ContributedResourceSerializer

  attribute :model_type do
    object.model_type.try(:title)
  end

  attribute :model_format do
    object.model_format.try(:title)
  end

  attribute :environment do
    object.recommended_environment.try(:title)
  end

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications

end

