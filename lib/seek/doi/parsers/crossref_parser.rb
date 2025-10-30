module Seek
  module Doi
    module Parsers
      class CrossrefParser < BaseParser
        CROSSREF_API_ENDPOINT = 'https://api.crossref.org/works'.freeze

        private

        def build_url(doi)
          URI("#{CROSSREF_API_ENDPOINT}/#{doi}")
        end

        def parse_response_body(response)
          json = JSON.parse(response.body)
          json['message']
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
          abstract.gsub(/<\/?jats:[^>]+>/, '').strip
        end

        def extract_date(data)
          get_date_parts = ->(key) do
            if data[key] && data[key]['date-parts'].is_a?(Array)
              data[key]['date-parts'].first
            end
          end

          date_parts = get_date_parts.call('issued') ||
                       get_date_parts.call('published') ||
                       get_date_parts.call('published-print')
          date_parts ? (Date.new(*date_parts) rescue nil) : nil
        end

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
          parts += ":#{pages || article}." if pages || article

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

      end
    end
  end
end
