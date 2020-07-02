class CustomMetadata < ApplicationRecord

  include Seek::JSONMetadata::Serialization

  belongs_to :item, polymorphic: true
  belongs_to :custom_metadata_type, validate: true

  validates_with CustomMetadataValidator

  delegate :custom_metadata_attributes, to: :custom_metadata_type
  alias :metadata_type :custom_metadata_type

  def custom_metadata_type=(type)
    super
    @data = Seek::JSONMetadata::Data.new(type)
    update_json_metadata
    type
  end

  def attribute_class
    CustomMetadataAttribute
  end
end
