class ExtendedMetadata < ApplicationRecord
  include Seek::JSONMetadata::Serialization

  belongs_to :item, polymorphic: true
  belongs_to :extended_metadata_type, validate: true
  belongs_to :extended_metadata_attribute

  validates_with ExtendedMetadataValidator

  delegate :extended_metadata_attributes, to: :extended_metadata_type

  # for polymorphic behaviour with sample
  alias_method :metadata_type, :extended_metadata_type

  def extended_metadata_type=(type)
    super
    @data = Seek::JSONMetadata::Data.new(type)
    update_json_metadata
    type
  end

  def attribute_class
    ExtendedMetadataAttribute
  end
end
