require 'rest-client'

module Galaxy
  class Client
    ENDPOINT = 'https://usegalaxy.eu/api'.freeze

    def initialize(endpoint = nil)
      endpoint ||= ENDPOINT
      @endpoint = RestClient::Resource.new(endpoint)
    end

    def tools
      perform('tools')
    end

    private

    def perform(path, method: :get, **opts)
      opts.reverse_merge!(accept: 'application/json')
      res = @endpoint[path].send(method, opts)
      JSON.parse(res.body)
    end
  end
end
