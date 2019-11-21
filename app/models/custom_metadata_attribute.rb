class CustomMetadataAttribute < ApplicationRecord

  belongs_to :sample_attribute_type

  def validate_value?(value)
    return false if required? && value.blank?
    (value.blank? && !required?) || sample_attribute_type.validate_value?(value, required: required?)
  end

end