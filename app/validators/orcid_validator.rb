class OrcidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || valid_orcid_id?(value.gsub(%r{http(s)?\:\/\/orcid.org\/}, ''))
    record.errors[attribute] << (options[:message] || "isn't a valid ORCID identifier")
  end

  private

  # checks the structure of the id, and whether is conforms to ISO/IEC 7064:2003
  def valid_orcid_id?(id)
    if id =~ /[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9,X]{4}/
      id = id.delete('-')
      id[15] == orcid_checksum(id)
    else
      false
    end
  end

  # calculating the checksum according to ISO/IEC 7064:2003, MOD 11-2 ; see - http://support.orcid.org/knowledgebase/articles/116780-structure-of-the-orcid-identifier
  def orcid_checksum(id)
    total = 0
    (0...15).each { |x| total = (total + id[x].to_i) * 2 }
    remainder = total % 11
    result = (12 - remainder) % 11
    result == 10 ? 'X' : result.to_s
  end
end
