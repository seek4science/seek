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

        private

        # DataCite creators may give a personal name only as "Family, Given" in 'name'.
        # Split it when the creator is personal: either explicitly (nameType 'Personal'), or
        # implicitly (no nameType) when the name doesn't look like an organisation.
        def author_from_name(a)
          name = a['name'].to_s.strip
          if personal_name?(a, name) && name.count(',') == 1
            family, given = name.split(',', 2).map(&:strip)
            return Seek::Doi::Author.new(first_name: given, last_name: family) if family.present? && given.present?
          end
          super
        end

        def personal_name?(a, name)
          case a['nameType']
          when 'Personal' then true
          when 'Organizational' then false
          else !name.match?(ORGANISATION_PATTERN)
          end
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
