require 'net/http'
require 'json'

module Seek
  module Doi
    module Parsers
      class DataciteParser < BaseParser
        API_BASE = 'https://api.datacite.org/dois/'.freeze

        def parse(doi)
          id = doi.sub(%r{^https?://(dx\.)?doi\.org/}, '')
          response = Net::HTTP.get(URI("#{API_BASE}#{id}"))
          data = JSON.parse(response)['data']['attributes'] rescue {}

          normalize_metadata(
            title: data.dig('titles', 0, 'title'),
            authors: data['creators']&.map { |c| c['name'] },
            journal: data['container-title'],
            date: data['published'],
            doi: doi,
            abstract: data['descriptions']&.first&.dig('description'),
            publisher: data['publisher'],
            url: data['url']
          )
        end
      end
    end
  end
end

