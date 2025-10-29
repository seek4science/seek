module Seek
  module Doi
    module Parsers
      class DataciteParser < BaseParser
        DATACITE_API_ENDPOINT = 'https://api.datacite.org/dois'.freeze

        private

        def build_url(doi)
          URI("#{DATACITE_API_ENDPOINT}/#{doi}")
        end

        def parse_response_body(response)
          json = JSON.parse(response.body)
          json.dig('data', 'attributes')
        end

        def extract_metadata(data)
          {
            type: data.dig('types', 'resourceTypeGeneral') || 'unspecified',
            title: Array(data['titles']).first&.[]('title'),
            abstract: extract_abstract(data),
            date_published: extract_date(data)&.to_s,
            journal: data.dig('container', 'title'),
            doi: data['doi'],
            publisher: data['publisher'],
            authors: extract_authors_as_objects(data['creators']),
            editors: extract_editors(data['contributors']).join(' and '),
            url: data['url'],
            volume: data.dig('container', 'volume'),
            issue: data.dig('container', 'issue'),
            page: data.dig('container', 'firstPage'),
            location: extract_location(data)
          }
        end

        def extract_abstract(data)
          desc = Array(data['descriptions']).find { |d| d['descriptionType'] == 'Abstract' }
          desc&.[]('description')&.strip
        end

        def extract_date(data)
          if data['publicationYear']
            Date.new(data['publicationYear'].to_i)
          elsif (issued = Array(data['dates']).find { |d| d['dateType'] == 'Issued' })
            Date.parse(issued['date']) rescue nil
          end
        end

        def extract_location(data)
          Array(data['geoLocations']).first&.[]('geoLocationPlace')
        end
      end
    end
  end
end
