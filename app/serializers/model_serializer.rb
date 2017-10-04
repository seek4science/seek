class ModelSerializer < ContributedResourceSerializer
  attributes :model_type, :model_format
  attribute :environment do
    object.recommended_environment
  end
end

