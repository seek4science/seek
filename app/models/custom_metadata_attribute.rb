class CustomMetadataAttribute < ApplicationRecord
  belongs_to :sample_attribute_type
  belongs_to :custom_metadata_type

  METHOD_PREFIX = '_custom_metadata_'.freeze

  def validate_value?(value)
    return false if required? && value.blank?
    (value.blank? && !required?) || sample_attribute_type.validate_value?(value, required: required?)
  end

  def hash_key
    title#.parameterize.underscore + '_' + id.to_s
  end

  def resolve(value)
    resolution = if sample_attribute_type.resolution.present? && sample_attribute_type.regexp.present?
                   value.sub(Regexp.new(sample_attribute_type.regexp), sample_attribute_type.resolution)
                 end
    resolution
  end

  # to behave like a sample attribute, but is never a title
  def is_title
    false
  end

  # The method name used to get this attribute via a method call
  def method_name
    METHOD_PREFIX + hash_key
  end

  alias accessor_name hash_key
end
