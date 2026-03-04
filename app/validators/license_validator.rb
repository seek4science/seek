class LicenseValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    normalized_license = Seek::License.normalize(value)
    if Seek::License.find(normalized_license)
      record.send("#{attribute}=", normalized_license)
      return
    end
    record.errors.add(attribute, options[:message] || "isn't a recognized license")
  end

end