class LicenseValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if Seek::License.find(value)
    # Try looking up by URI
    license = Seek::License.normalize(license)
    if license
      record.send("#{attribute}=", license)
      return
    end
    record.errors.add(attribute, options[:message] || "isn't a recognized license")
  end

end