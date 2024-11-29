class LicenseValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if Seek::License.find(value)
    # Try looking up by URI
    if value.start_with? /https?:/
      id = Seek::License.uri_to_id(value)
      if id
        record.send("#{attribute}=", id)
        return
      end
    end
    record.errors.add(attribute, options[:message] || "isn't a recognized license")
  end

end