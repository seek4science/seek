module Seek
  module Doi
    module Parsers
      class DataciteParser < BaseParser
        DATACITE_API_ENDPOINT = 'https://api.datacite.org/dois'.freeze

        # Words that suggest a creator name belongs to an organisation rather than a person.
        ORGANISATION_PATTERN = /\b(
          universit\w* | institut\w* | cent(?:er|re)s? | laborator(?:y|ies) | department | faculty |
          consortium | foundation | society | association | network | project | initiative |
          group | team | hospital | college | school | academy | ministry | agency | council |
          inc\.? | ltd\.? | gmbh | llc | e\.\s?v\.? | corporation
        )(?=\W|\z)/ix

        # Lowercase surname particles that belong to the family name, e.g. "Ludwig van Beethoven".
        SURNAME_PARTICLES = %w[van von der den de del della di da das dos du la le ten ter].freeze

        private

        # DataCite creators may give a personal name only in 'name', either as "Family, Given"
        # (the DataCite convention) or as "Given Family". Split it when the creator is personal;
        # otherwise keep the whole name as the first name.
        def author_from_name(a)
          name = a['name'].to_s.strip
          return super unless personal_name?(a, name)

          given, family = case name.count(',')
                          when 1 then name.split(',', 2).map(&:strip).reverse
                          when 0 then split_given_family(name)
                          end
          return super if given.blank? || family.blank?

          Seek::Doi::Author.new(first_name: given, last_name: family)
        end

        # Personal if stated by nameType or an ORCID; organisational if stated by nameType or a ROR id;
        # otherwise personal unless the name contains a typical organisation word.
        def personal_name?(a, name)
          schemes = Array(a['nameIdentifiers']).map { |i| i['nameIdentifierScheme'].to_s.upcase }
          case a['nameType']
          when 'Personal' then true
          when 'Organizational' then false
          else
            return true if schemes.include?('ORCID')
            return false if schemes.include?('ROR')

            !name.match?(ORGANISATION_PATTERN)
          end
        end

        # "Given Middle Family" -> ["Given Middle", "Family"], keeping surname particles with the family name.
        def split_given_family(name)
          words = name.split(/\s+/)
          return if words.size < 2

          index = words.size - 1
          index -= 1 while index > 1 && SURNAME_PARTICLES.include?(words[index - 1])
          [words[0...index].join(' '), words[index..].join(' ')]
        end

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
            begin
              Date.parse(issued['date'])
            rescue
              nil
            end
          end
        end

        def extract_location(data)
          Array(data['geoLocations']).first&.[]('geoLocationPlace')
        end
      end
    end
  end
end
