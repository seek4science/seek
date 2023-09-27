class CustomMetadataValidator < ActiveModel::Validator
  def validate(record)
    record.custom_metadata_attributes.each do |attribute|
      val = record.get_attribute_value(attribute)
      validate_attribute(record, attribute, val)
    end
  end

  private

  def validate_attribute(record, attribute, value, prefix = '')
    if attribute.test_blank?(value)
      record.errors.add("#{prefix}#{attribute.title}", 'is required') if attribute.required?
    else
      unless attribute.validate_value?(value)
        record.errors.add("#{prefix}#{attribute.title}", "is not a valid #{attribute.sample_attribute_type.title}")
      end
    end

    if attribute.linked_custom_metadata?
      attribute.linked_custom_metadata_type.custom_metadata_attributes.each do |attr|
        validate_attribute(record, attr, value ? value[attr.accessor_name.to_s] : nil, "#{attribute.title}.")
      end
    elsif attribute.linked_custom_metadata_multi?
      linked_attributes = attribute.linked_custom_metadata_type.custom_metadata_attributes
      value.each_with_index do |val, index|
        linked_attributes.each do |attr|
          validate_attribute(record, attr, val ? val[attr.accessor_name.to_s] : nil, "#{attribute.title}.#{index + 1}.")
        end
      end
    end
  end
end