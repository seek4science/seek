class ExtendedMetadataAttribute < ApplicationRecord
  include Seek::JsonMetadata::Attribute

  belongs_to :extended_metadata_type
  belongs_to :linked_extended_metadata_type, class_name: 'ExtendedMetadataType'
  has_many :extended_metadatas

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
