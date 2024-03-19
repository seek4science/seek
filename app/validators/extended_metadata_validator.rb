class ExtendedMetadataValidator < ActiveModel::Validator
  def validate(record)
    record.extended_metadata_attributes.each do |attribute|
      val = record.get_attribute_value(attribute)
      validate_attribute(record, attribute, val)
    end

    if record.new_record? && !record.enabled?
      record.errors.add(:extended_metadata_type, "is not enabled, which is invalid for a new record")
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

    if attribute.linked_extended_metadata?
      attribute.linked_extended_metadata_type.extended_metadata_attributes.each do |attr|
        validate_attribute(record, attr, value ? value[attr.accessor_name.to_s] : nil, "#{attribute.title}.")
      end
    elsif attribute.linked_extended_metadata_multi?
      linked_attributes = attribute.linked_extended_metadata_type.extended_metadata_attributes
      value.each_with_index do |val, index|
        linked_attributes.each do |attr|
          validate_attribute(record, attr, val ? val[attr.accessor_name.to_s] : nil, "#{attribute.title}.#{index + 1}.")
        end
      end
    end
  end
end