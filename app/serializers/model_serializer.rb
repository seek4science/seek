class ModelSerializer < BaseSerializer
  attributes :title, :description, :latest_version, :version, :versions
  attributes :model_type, :model_format
  attribute :environment do
    object.recommended_environment
  end

  has_many :content_blob, include_data:true do
    object.content_blobs
  end
end
