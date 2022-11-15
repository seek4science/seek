class LicenseValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if Seek::License.find(value)
    record.errors.add(attribute, options[:message] || "isn't a valid license ID")
  end

end