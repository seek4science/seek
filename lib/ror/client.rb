module Ror
  class Client
    ENDPOINT = 'https://api.ror.org/v2'.freeze


    def initialize(endpoint = ENDPOINT)
      @endpoint = RestClient::Resource.new(endpoint)
    end

    # Search for an institution by name
    def query_name(query)
      encoded_query = URI.encode_www_form_component(query)
      response = request("organizations?query=#{encoded_query}*")
      items = response['items']&.map { |item| extract_details(item) } || []
      {items: items}
    end

    # define a method to extract the ror id from the link "https://ror.org/04rcqnp59"

    def extract_ror_id(ror_link)
      return nil unless ror_link.is_a?(String) && ror_link.match?(%r{\Ahttps://ror\.org/\w+\z})
      ror_link.split('/').last
    end

    RECORD_CACHE_EXPIRY = 7.days

    # The full ROR record (https://ror.readme.io/docs/data-structure) for the ROR ID, as a Hash, or { error: message }
    # if it couldn't be fetched. Records are cached, but errors are not.
    def fetch_record(ror_id)
      return { error: 'No ROR ID given' } if ror_id.blank?

      key = "ror/v2/organizations/#{ror_id}"
      cached = Rails.cache.read(key)
      return cached if cached

      response = request("organizations/#{ror_id}")
      if response.key?(:error)
        Rails.logger.warn("Unable to fetch ROR record #{ror_id}: #{response[:error]}")
      else
        Rails.cache.write(key, response, expires_in: RECORD_CACHE_EXPIRY)
      end
      response
    end

    # Fetch institution details by ROR ID
    def fetch_by_id(ror_id)
      response = fetch_record(ror_id)
      response.key?(:error) ? response : extract_details(response)
    end

    private

    # Generic method to make requests and handle errors
    def request(path)
      response = @endpoint[path].get(accept: 'application/json')
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      error_response = JSON.parse(e.response.body) rescue nil
      if error_response && error_response["errors"]
        { error: error_response["errors"].join(", ") }
      else
        { error: e.message }
      end
    rescue StandardError => e
      { error: "Unexpected error: #{e.message}" }
    end


    def extract_details(data)
      begin
        location = data['locations']&.first&.dig('geonames_details') || {}
        names = data['names'] || []

        name = names.find { |n| (n['types'] || []).include?('ror_display') }&.[]('value') || ''
        alt_names = names.reject { |n| (n['types'] || []).include?('ror_display') }
                         .map { |n| n['value'] }.uniq.join(', ')

        webpage = (data['links'] || []).find { |l| l['type'] == 'website' }&.[]('value')
        type = (data['types'] || []).first

        {
          name: name,
          id: extract_ror_id(data['id']) || '',
          type: type,
          altNames: alt_names,
          country: location['country_name'] || 'N/A',
          countrycode: location['country_code'] || 'N/A',
          city: location['name'] || 'N/A',
          webpage: webpage
        }
      rescue => e
        puts "Error extracting data info: #{e.message}"
        {}
      end
    end


  end
end
