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
          return nil unless response.is_a?(Net::HTTPSuccess)

          begin
            data = parse_response_body(response)
            raise "Missing metadata in response" unless data

            data = decode_html_entities_in_hash(data)
            metadata = extract_metadata(data)
            metadata[:citation] ||= build_citation(metadata)

            build_struct(metadata)
          rescue JSON::ParserError => e
            Rails.logger.error("JSON parse error for DOI #{doi}: #{e.message}")
            nil
          rescue StandardError => e
            Rails.logger.error("Unexpected error parsing DOI #{doi}: #{e.message}")
            nil
          end
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
            Rails.logger.debug("HTTP #{response.code} #{response.message} for #{uri}")
            response
          end
        rescue SocketError, Timeout::Error, StandardError => e
          Rails.logger.error("Network error fetching #{uri}: #{e.message}")
          nil
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
