#todo error handling/logging
require 'cgi'

module Seek
  module Doi
    module Parsers
      class CrossrefParser < BaseParser
        CROSSREF_API_ENDPOINT = 'https://api.crossref.org/works'.freeze

        def parse(doi)
          url = URI("#{CROSSREF_API_ENDPOINT}/#{doi}")
          Rails.logger.info("Fetching Crossref metadata for DOI #{doi} from #{url}")

          response = perform_request(url)
          return nil unless response.is_a?(Net::HTTPSuccess)

          begin
            json = JSON.parse(response.body)
            data = json['message']
            raise "Missing 'message' in Crossref response" unless data

            data = decode_html_entities_in_hash(data)
            metadata = extract_metadata(data)
            metadata[:citation] = build_citation(metadata)

            build_struct(metadata)
          rescue JSON::ParserError => e
            Rails.logger.error("JSON parse error for Crossref DOI #{doi}: #{e.message}")
            nil
          rescue StandardError => e
            Rails.logger.error("Unexpected error parsing Crossref DOI #{doi}: #{e.message}")
            nil
          end
        end

        private


        def perform_request(uri)
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new(uri)
            request['Accept'] = 'application/json'
            response = http.request(request)
            Rails.logger.debug("HTTP #{response.code} #{response.message} for #{uri}")
            response
          end
        rescue SocketError, Timeout::Error => e
          Rails.logger.error("Network error fetching #{uri}: #{e.message}")
          nil
        end

        def extract_metadata(data)
          {
            type: data['type'] || 'unspecified',
            title: [Array(data['title']).first, Array(data['subtitle']).first].compact.join(':'),
            abstract: clean_abstract(data['abstract']),
            date_published: extract_date(data)&.to_s,
            journal: Array(data['container-title']).last,
            short_journal_title: Array(data['short-container-title']).last,
            doi: data['DOI'],
            publisher: data['publisher'],
            booktitle: data['container-title'].last,
            editors: extract_editors(data['editor']).join(' and '),
            authors: extract_authors_as_objects(data['author']),
            url: data['URL'],
            volume: data['volume'],
            issue: data['issue'],
            page: data['page'],
            location: data['event']&.[]('location') || data['publisher-location'],
            article_number: data['article-number']
          }
        end

        def clean_abstract(abstract)
          return nil if abstract.nil?

          # Remove all <jats:*> tags and their closing tags
          cleaned = abstract.gsub(/<\/?jats:[^>]+>/, '')

          # Optional: remove leading/trailing whitespace
          cleaned.strip
        end

        def extract_date(data)
          # Helper to extract date-parts from a key
          get_date_parts = ->(key) {
            if data[key] && data[key]['date-parts'].is_a?(Array)
              data[key]['date-parts'].first
            end
          }

          # Try issued first, then published, then published-print
          date_parts = get_date_parts.call('issued') ||
            get_date_parts.call('published') ||
            get_date_parts.call('published-print')

          # Return Date object or nil if invalid
          date_parts ? (Date.new(*date_parts) rescue nil) : nil
        end

        def extract_editors(editor_list)
          #todo improve editor formatting
          return [] unless editor_list.is_a?(Array)
          editor_list.map { |e| [e['given'], e['family']].compact.join(' ') }
        end

        # Returns an array of DOI::Author objects
        def extract_authors_as_objects(author_list)
          return [] unless author_list.is_a?(Array)

          author_list.map do |a|
            if a['given'] && a['family']
              Seek::Doi::Author.new(first_name: a['given'], last_name: a['family'])
            elsif a['name']
              Seek::Doi::Author.new(first_name: a['name'], last_name: '')
            else
              nil
            end
          end.compact
        end


        # https://api.crossref.org/types for type list
        def build_citation(data)
          case data[:type]
          when 'book-chapter'
            format_crossref_in_collection_citation(data)
          when 'book', 'monograph'
            format_crossref_book_citation(data)
          when 'journal-article'
            format_crossref_journal_citation(data)
          when 'proceedings-article'
            format_crossref_in_collection_citation(data)
          when 'proceedings'
            format_crossref_proceedings_citation(data)
          when 'posted-content'
            format_crossref_preprint_citation(data)
          else
            default_citation(data)
          end
        end


        def format_crossref_journal_citation(data)
          journal = data[:short_journal_title].presence || data[:journal]
          volume  = data[:volume].presence
          issue   = data[:issue].presence
          pages   = data[:page].presence
          article = data[:article_number].presence

          # Build the core part: "Journal 585(7825):357–362" or "J Chem Inf Model:acs.jcim.5c01488"
          parts = [journal, volume].compact.join(' ')
          parts += "(#{issue})" if issue
          parts += ":#{pages || article}" if pages || article

          parts.squish
        end


        #book-chapter + proceedings-article
        def format_crossref_in_collection_citation(data)
          book_title         = data[:booktitle]
          publisher          = data[:publisher]
          location = data[:location].to_s.strip
          pages              = data[:page]
          pages_str =
            if pages.present?
              pages.to_s.include?('-') || pages.to_s.include?('–') ? ", pp #{pages}" : ", p #{pages}"
            else
              ''
            end

          "In: #{book_title}. #{publisher}#{", #{location}" if location.present?}#{pages_str}".squish
        end


        def format_crossref_book_citation(data)
          publisher      = data[:publisher]
          location = data[:location] || ''
          "#{[publisher, location.presence].compact.join(', ')}".squish
        end

        def format_crossref_proceedings_citation(data)

          editors   = data[:editors]
          title     = data[:title]
          publisher = data[:publisher]
          location  = data[:location].strip
          editor_str = editors.present? ? "#{editors} (eds)" : ''

          citation_parts = []
          citation_parts << "#{editor_str}," if editors.present?
          citation_parts << "#{title}. #{publisher},"
          citation_parts << location if location.present?

          citation_parts.compact.join(' ').squish
        end

        def format_crossref_preprint_citation(data)

          repo = data[:journal]
          url = data[:url]

          citation_parts = []
          citation_parts << "Preprint."
          citation_parts << "#{repo}." if repo.present?
          citation_parts << "#{url}" if url.present?
          citation_parts.compact.join(' ').squish
        end

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
