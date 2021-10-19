class CustomMetadataAttribute < ApplicationRecord
  include Seek::JSONMetadata::Attribute

  belongs_to :custom_metadata_type

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
