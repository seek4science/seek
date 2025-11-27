require 'net/http'
require 'json'
require 'cgi'
require 'ostruct'

module Seek
  module Doi
    module Parsers
      class BaseParser
        def parse(doi)
          url = build_url(doi)
          Rails.logger.info("Fetching metadata for DOI #{doi} from #{url}")

          response = perform_request(url)
          data = parse_response_body(response)

          raise Seek::Doi::ParseException, "Empty metadata response for DOI #{doi}" if data.blank?

          metadata = decode_html_entities_in_hash(extract_metadata(data))
          metadata[:citation] ||= build_citation(metadata)

          build_struct(metadata)

        rescue JSON::ParserError => e
          raise Seek::Doi::ParseException, "Error parsing JSON for DOI #{doi}: #{e.message}"
        rescue Seek::Doi::BaseException
          raise
        rescue StandardError => e
          raise Seek::Doi::ParseException, "Unexpected error while parsing DOI #{doi}: #{e.message}"
        end


        protected

        def normalize_metadata(raw)
          {
            type: raw[:type],
            title: raw[:title],
            authors: raw[:authors],
            journal: raw[:journal],
            date_published: raw[:date_published],
            doi: raw[:doi],
            abstract: raw[:abstract],
            citation: raw[:citation],
            editors: raw[:editors],
            booktitle: raw[:booktitle],
            publisher: raw[:publisher],
            url: raw[:url],
            page: raw[:page]
          }.compact
        end

        # Must be implemented in subclasses
        def build_url(_doi)
          raise NotImplementedError, "#{self.class.name} must implement #build_url"
        end

        # Must be implemented in subclasses
        def parse_response_body(_response)
          raise NotImplementedError, "#{self.class.name} must implement #parse_response_body"
        end

        def build_struct(raw)
          OpenStruct.new(normalize_metadata(raw))
        end

        # optional for subclasses to override
        def build_citation(_data)
          default_citation(_data)
        end



        # Generic network handler
        def perform_request(uri, accept_header: 'application/json')
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new(uri)
            request['Accept'] = accept_header
            response = http.request(request)

            case response.code.to_i
            when 200
              response
            when 204
              raise Seek::Doi::FetchException, "No metadata available for DOI #{uri}"
            when 404
              raise Seek::Doi::NotFoundException, "DOI not found: #{uri}"
            else
              raise Seek::Doi::FetchException, "Unexpected HTTP #{response.code} #{response.message} for #{uri}"
            end
          end
        rescue SocketError, Timeout::Error => e
          raise Seek::Doi::FetchException, "Network error fetching DOI metadata: #{e.message}"
        rescue URI::InvalidURIError => e
          raise Seek::Doi::MalformedDOIException, "Invalid DOI or malformed URI: #{e.message}"
        end


        # HTML decoding utility
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

        # Generic helpers for author/editor parsing
        def extract_authors_as_objects(list)
          return [] unless list.is_a?(Array)

          list.map do |a|
            if a['given'] && a['family']
              Seek::Doi::Author.new(first_name: a['given'], last_name: a['family'])
            elsif a['givenName'] && a['familyName']
              Seek::Doi::Author.new(first_name: a['givenName'], last_name: a['familyName'])
            elsif a['name']
              Seek::Doi::Author.new(first_name: a['name'], last_name: '')
            end
          end.compact
        end

        def extract_editors(list)
          return [] unless list.is_a?(Array)
          list.map { |e| [e['given'], e['family'], e['givenName'], e['familyName']].compact.first(2).join(' ') }
        end

        def default_citation(data)
          parts = []
          parts << data[:publisher] if data[:publisher]
          parts << data[:url] if data[:url]
          parts.join('. ') + (parts.empty? ? '' : '.')
        end

      end
    end
  end
end
