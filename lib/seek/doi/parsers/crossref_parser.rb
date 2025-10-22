#todo error handling/logging
module Seek
  module Doi
    module Parsers
      class CrossrefParser < BaseParser
        CSL_JSON_HEADERS = { 'Accept' => 'application/vnd.citationstyles.csl+json' }.freeze
        DOI_API_ENDPOINT = 'https://api.crossref.org/works'.freeze

        def parse(doi)
          url = "#{DOI_API_ENDPOINT}/#{doi}"
          puts "================== Fetching Crossref JSON from URL: =================="
          puts url

          data = JSON.parse(URI.open(url).read)["message"]

          Rails.logger.info("Crossref JSON data for DOI #{doi}: #{data.inspect}")

          metadata = extract_metadata(data)
          metadata[:citation] = build_citation(metadata)

          build_struct(metadata)
        end


        private

        def fetch_csl_json(doi)
          url = "#{Seek::Doi::Parser::DOI_ENDPOINT}/#{doi}"
          puts "================== Fetching CSL JSON from URL: #{url} =================="
          JSON.parse(URI.open(url, CSL_JSON_HEADERS).read)
        rescue StandardError => e
          Rails.logger.warn("Failed to fetch CSL JSON for DOI #{doi}: #{e.message}")
          {}
        end

        def extract_metadata(data)
          {
            type: data['type'] || 'unspecified',
            title: [Array(data['title']).first, Array(data['subtitle']).first].compact.join(':'),
            abstract: clean_abstract(data['abstract']),
            date_published: extract_date(data)&.to_s,
            journal: Array(data['container-title']).last,
            doi: data['DOI'],
            publisher: data['publisher'],
            booktitle: data['container-title'].last,
            editors: extract_editors(data['editor']).join(' and '),
            authors: extract_authors_as_objects(data['author']),
            url: data['URL'],
            volume: data['volume'],
            issue: data['issue'],
            page: data['page'],
            publisher_location: data['publisher-location']
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


        def build_citation(data)
          case data[:type]
          when 'book-chapter'
            format_crossref_book_chapter_citation(data)
          when 'journal-article'
            format_crossref_journal_article_citation(data)
          when 'proceedings-article'
            format_crossref_proceedings_article_citation(data)
          else
            default_citation(data)
          end
        end

        def format_crossref_book_chapter_citation(data)

          editors        = data[:editors]
          book_title     = data[:booktitle]
          publisher      = data[:publisher]
          publisher_location = data[:publisher_location] || ''
          pages = data[:page]
          editor_str = editors.blank? ? '' : "#{editors} (eds)"
          pages_str  = pages.blank? ?  '' : ", pp #{pages}"
          "In: #{editor_str} #{book_title}. #{publisher}, #{publisher_location}#{pages_str}".squish

        end



        def format_crossref_journal_article_citation(m)
          authors = m[:authors].map(&:to_s).join(', ')
          year = m[:date_published]&.slice(0, 4)
          "#{authors} (#{year}) #{m[:title]}. #{m[:journal]}. #{m[:publisher]}."
        end

        def format_crossref_proceedings_article_citation(metadata)

        end

        def default_citation(m)
          year = m[:date_published]&.slice(0, 4)
          "#{m[:journal]}. #{year}."
        end


      end
    end
  end
end
