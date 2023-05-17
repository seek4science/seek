class CustomMetadataAttribute < ApplicationRecord
  include Seek::JSONMetadata::Attribute

  belongs_to :custom_metadata_type
  belongs_to :linked_custom_metadata_type, class_name: 'CustomMetadataType'
  has_many :custom_metadatas

  # to behave like a sample attribute, but is never a title
  def is_title
    false
  end

  def linked_sample_type
    nil
  end

  def label
    super || title&.humanize
  end
end
