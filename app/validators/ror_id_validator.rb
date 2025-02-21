require 'net/http'
require 'uri'
require 'json'

class RorIdValidator < ActiveModel::EachValidator
  VALID_ROR_ID_REGEX = /\A[0-9a-zA-Z]{9}\z/
  ROR_API_BASE_URL = "https://api.ror.org/organizations/"

  # Allow blank values
  def validate_each(record, attribute, value)
    return if value.blank?

    # check format
    unless value.match?(VALID_ROR_ID_REGEX)
      record.errors.add(attribute, "ID must be a valid ROR ID format.")
      return
    end

    # check if ROR ID exists using the ROR API
    unless valid_ror_id?(value)
      record.errors.add(attribute, "ID does not match any existing ROR organization.")
    end
  end

  private

  def valid_ror_id?(ror_id)
    url = URI.parse("#{ROR_API_BASE_URL}#{ror_id}")
    pp "url: #{url}"
    response = Net::HTTP.get_response(url)
    pp "response: #{response}"
    response.is_a?(Net::HTTPSuccess) && JSON.parse(response.body)["id"].present?
  rescue StandardError
    false
  end
end
