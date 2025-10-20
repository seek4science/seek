module Seek
  module Doi
    module Parsers
      class CrossrefParser < BaseParser
        CSL_JSON_HEADERS = { 'Accept' => 'application/vnd.citationstyles.csl+json' }.freeze

        def parse(doi)
          data = fetch_csl_json(doi)

          # log data
          Rails.logger.info("CSL JSON data for DOI #{doi}: #{data.inspect}")


          doi_record = OpenStruct.new(
            title: [Array(data['title']).first, Array(data['subtitle']).first].compact.join(':'),
            abstract: clean_abstract(data['abstract']),
            date_published: extract_date(data),
            journal: data['container-title'],
            doi: data['DOI'],
            citation: data['citation'] || build_citation(data),
            publisher: data['publisher'],
            booktitle: data['collection-title'] || data['book-title'],
            editors: extract_editors(data['editor']),
            authors: extract_authors_as_objects(data['author']),
            url: data['URL']
          )

          normalize_metadata(
            title: doi_record.title,
            abstract: doi_record.abstract,
            date_published: doi_record.date_published.to_s,
            journal: doi_record.journal,
            doi: doi_record.doi,
            citation: doi_record.citation,
            publisher: doi_record.publisher,
            booktitle: doi_record.booktitle,
            editors: doi_record.editors.join(' and '),
            authors: doi_record.authors,
            url: data['URL']
          )
        end

        private

        def fetch_csl_json(doi)
          url = "#{Seek::Doi::Parser::DOI_ENDPOINT}/#{doi}"
          JSON.parse(URI.open(url, CSL_JSON_HEADERS).read)
        rescue StandardError => e
          Rails.logger.warn("Failed to fetch CSL JSON for DOI #{doi}: #{e.message}")
          {}
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
            Seek::Doi::Author.new(first_name: a['given'], last_name: a['family'])
          end
        end

        def build_citation(data)
          #todo improve citation formatting
          journal = data['container-title']
          year = extract_date(data)&.year
          "#{journal}. #{year}."
        end

      end
    end
  end
end
