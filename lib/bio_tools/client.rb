require 'rest-client'

module BioTools
  class Client
    ENDPOINT = 'https://bio.tools/api'.freeze

    def initialize(endpoint = nil)
      endpoint ||= ENDPOINT
      @endpoint = RestClient::Resource.new(endpoint)
    end

    def filter(query, page: 1, sort: 'score')
      perform('tool', params: { q: query, sort: sort, page: page })
    end

    def tool(id)
      perform("tool/#{id}")
    end

    private

    def perform(path, method: :get, **opts)
      opts.reverse_merge!(accept: 'application/json')
      res = @endpoint[path].send(method, opts)
      JSON.parse(res.body)
    end
  end
end
