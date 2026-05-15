class ExtendedMetadataAttribute < ApplicationRecord
  include Seek::JSONMetadata::Attribute

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
    label_value = read_attribute(:label)
    label_value.nil? ? title&.humanize : label_value
  end
end
