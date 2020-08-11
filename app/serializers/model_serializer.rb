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

  attribute :model_image_link do
     if version_number
       unless object.find_version(version_number).model_image.nil?
        base_url+polymorphic_path([object, object.find_version(version_number).model_image])
       end
     else
       unless object.model_image.nil?
        base_url+polymorphic_path([object, object.model_image])
       end
     end
  end

  has_many :organisms
  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
end
