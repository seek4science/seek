require 'net/http'
require 'json'
require 'cgi'

module Seek
  module Doi
    module Parsers
      class DataciteParser < BaseParser
        DATACITET_API_ENDPOINT = 'https://api.datacite.org/dois'.freeze

        def parse(doi)
          url = URI("#{DATACITET_API_ENDPOINT}/#{doi}")
          puts "================== Fetching DataCite JSON from URL: =================="
          puts url
          Rails.logger.info("Fetching DataCite metadata for DOI #{doi} from #{url}")

          response = perform_request(url)
          return nil unless response.is_a?(Net::HTTPSuccess)

          begin

            json = JSON.parse(response.body)
            data = json.dig('data', 'attributes')
            raise "Missing 'attributes' in DataCite response" unless data

            data = decode_html_entities_in_hash(data)
            metadata = extract_metadata(data)
            metadata[:citation] = default_citation(metadata)

            build_struct(metadata)
          rescue JSON::ParserError => e
            Rails.logger.error("JSON parse error for DataCite DOI #{doi}: #{e.message}")
            nil
          rescue StandardError => e
            Rails.logger.error("Unexpected error parsing DataCite DOI #{doi}: #{e.message}")
            nil
          end
        end

        private

        def perform_request(url)
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          http.open_timeout = 5
          http.read_timeout = 10

          request = Net::HTTP::Get.new(url)
          request['Accept'] = 'application/vnd.api+json'

          response = http.request(request)
          unless response.is_a?(Net::HTTPSuccess)
            Rails.logger.warn("DataCite API returned #{response.code} - #{response.message} for #{url}")
          end
          response
        rescue StandardError => e
          Rails.logger.error("HTTP error fetching DataCite metadata from #{url}: #{e.message}")
          nil
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
            editors: extract_editors(data['contributors']),
            url: data['url'],
            volume: data.dig('container', 'volume'),
            issue: data.dig('container', 'issue'),
            page: data.dig('container', 'firstPage'),
            location: extract_location(data),
            citation: default_citation(data)
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

        def extract_authors_as_objects(creators)
          return [] unless creators.is_a?(Array)
          creators.map do |a|
            if a['givenName'] && a['familyName']
              Seek::Doi::Author.new(first_name: a['givenName'], last_name: a['familyName'])
            elsif a['name']
              Seek::Doi::Author.new(first_name: a['name'], last_name: '')
            end
          end.compact
        end

        def extract_editors(contributors)
          return [] unless contributors.is_a?(Array)
          contributors.select { |c| c['contributorType'] == 'Editor' }
                      .map { |e| [e['givenName'], e['familyName']].compact.join(' ') }
        end

        def extract_location(data)
          Array(data['geoLocations']).first&.[]('geoLocationPlace')
        end

        # --- Citation Builders ---

        def default_citation(data)
          parts = []
          if data[:publisher]
            parts << data[:publisher]
          end
          if data[:url]
            parts << data[:url]
          end
          parts.join('. ') + (parts.empty? ? '' : '.')
        end


        def decode_html_entities_in_hash(hash)
          hash.transform_values do |value|
            case value
            when String
              CGI.unescapeHTML(value)
            when Array
              value.map { |v| v.is_a?(String) ? CGI.unescapeHTML(v) : v }
            when Hash
              decode_html_entities_in_hash(value)
            else
              value
            end
          end
        end
      end
    end
  end
end
