class SampleAttributeValidator < ActiveModel::Validator
  def validate(record)
    return unless record.sample_type
    record.sample_type.sample_attributes.each do |attribute|
      val = record.get_attribute_value(attribute)
      if attribute.test_blank?(val)
        record.errors.add(attribute.title, 'is required') if attribute.required?
      else
        unless attribute.validate_value?(val)
          record.errors.add(attribute.title, "is not a valid #{attribute.sample_attribute_type.title}")
        end
      end
    end
  end
end
