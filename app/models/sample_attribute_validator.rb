class SampleAttributeValidator < ActiveModel::Validator
  def validate(record)
    return unless record.sample_type
    record.sample_type.sample_attributes.each do |attribute|
      val = record.get_attribute(attribute.hash_key)
      if val.blank?
        record.errors[attribute.method_name] << 'is required' if attribute.required?
      else
        unless attribute.validate_value?(val)
          record.errors[attribute.method_name] << "is not a valid #{attribute.sample_attribute_type.title}"
        end
      end
    end
  end
end
