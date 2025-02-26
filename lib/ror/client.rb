module ROR
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
      { error: "ROR API error: #{e.response}" }
    rescue StandardError => e
      { error: "Unexpected error: #{e.message}" }
    end
  end
end
