class CustomMetadata < ApplicationRecord
  include Seek::JSONMetadata::Serialization

  belongs_to :item, polymorphic: true
  belongs_to :custom_metadata_type, validate: true
  belongs_to :custom_metadata_attribute

  validates_with CustomMetadataValidator

  delegate :custom_metadata_attributes, to: :custom_metadata_type

  # for polymorphic behaviour with sample
  alias_method :metadata_type, :custom_metadata_type

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
