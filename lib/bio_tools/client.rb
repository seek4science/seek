require 'rest-client'

module BioTools
  class Client
    ENDPOINT = 'https://bio.tools/api'.freeze

    def initialize(endpoint = nil)
      endpoint ||= ENDPOINT
      @endpoint = RestClient::Resource.new(endpoint)
    end

    def filter(query)
      @endpoint['tool'].get(params: { name: query }, accept: 'application/json')
    end

    def tool(id)
      @endpoint["tool/#{id}"].get(accept: 'application/json')
    end
  end
end
