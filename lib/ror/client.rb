module Ror
  class Client
    ENDPOINT = 'https://api.ror.org'.freeze

    def initialize(endpoint = ENDPOINT)
      @endpoint = RestClient::Resource.new(endpoint)
    end

    # Search for an institution by name
    def query_name(query)
      encoded_query = URI.encode_www_form_component(query)
      request("organizations?query=#{encoded_query}")
    end

    # define a method to extract the ror id from the link "https://ror.org/04rcqnp59"

    def extract_ror_id(ror_link)
      return nil unless ror_link.is_a?(String) && ror_link.match?(%r{\Ahttps://ror\.org/\w+\z})
      ror_link.split('/').last
    end

    # Fetch institution details by ROR ID
    def fetch_by_id(ror_id)
      request("organizations/#{ror_id}")
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
  end
end
