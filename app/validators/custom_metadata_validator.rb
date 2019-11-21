class CustomMetadataValidator < ActiveModel::Validator
  def validate(record)

    record.custom_metadata_attributes.each do |attribute|
      val = record.get_attribute_value(attribute)
      if record.blank_attribute?(attribute)
        record.errors[attribute.title] << 'is required' if attribute.required?
      else
        unless attribute.validate_value?(val)
          record.errors[attribute.title] << "is not a valid #{attribute.sample_attribute_type.title}"
        end
      end
    end
  end
end