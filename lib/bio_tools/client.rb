require 'rest-client'

module BioTools
  class Client
    ENDPOINT = 'https://bio.tools/api'.freeze
    BASE = 'https://bio.tools/'.freeze

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

    def self.tool_url(id)
      "#{BASE}#{id}"
    end

    def self.match_id(input)
      matches = input.match(/#{BASE}(.+)/)
      matches[1] if matches
    end

    private

    def perform(path, method: :get, **opts)
      opts.reverse_merge!(accept: 'application/json')
      res = @endpoint[path].send(method, opts)
      JSON.parse(res.body)
    end
  end
end
