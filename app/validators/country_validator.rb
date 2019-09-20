class CountryValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
      return if value.blank?
      value = convert_to_code(value)
      if (CountryCodes.country(value))
        record.country = value
      else
        record.errors[attribute] << (options[:message] || "isn't a valid country or code")
      end
  end

  def convert_to_code(value)
    CountryCodes.force_code(value)&.upcase
  end

end