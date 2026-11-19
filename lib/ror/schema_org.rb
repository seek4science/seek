module Ror
  # Describes a ROR record (https://ror.readme.io/docs/data-structure) as Schema.org JSON-LD, with the ROR IRI
  # (e.g. https://ror.org/027m9bs27) as its @id.
  class SchemaOrg
    TYPES = {
      'education' => 'EducationalOrganization',
      'healthcare' => 'MedicalOrganization',
      'company' => 'Corporation',
      'government' => 'GovernmentOrganization',
      'nonprofit' => 'NGO'
    }.freeze

    # the relationships described. Sub organizations (child) are left out, as there can be very many of them.
    RELATIONSHIPS = { 'parent' => 'parentOrganization' }.freeze

    def initialize(record)
      @record = record
    end

    def id
      @record['id']
    end

    def to_h
      {
        '@context' => { '@vocab' => 'https://schema.org/' },
        '@id' => id,
        '@type' => types,
        'name' => display_name,
        'alternateName' => alternate_names.presence,
        'url' => link('website'),
        'foundingDate' => @record['established']&.to_s,
        'sameAs' => same_as.presence,
        'location' => locations.presence
      }.merge(relationships).compact
    end

    def to_json_ld
      to_h.to_json
    end

    private

    def types
      (['Organization'] + Array(@record['types']).filter_map { |type| TYPES[type] }).uniq
    end

    def names
      Array(@record['names'])
    end

    def display_name
      names.detect { |name| Array(name['types']).include?('ror_display') }&.dig('value')
    end

    def alternate_names
      names.reject { |name| Array(name['types']).include?('ror_display') }.map do |name|
        name['lang'].present? ? { '@value' => name['value'], '@language' => name['lang'] } : name['value']
      end
    end

    def link(type)
      value = Array(@record['links']).detect { |link| link['type'] == type }&.dig('value')
      { '@id' => value } if value
    end

    # equivalent records elsewhere: Wikipedia, Wikidata, ISNI and the Crossref Funder Registry
    def same_as
      iris = []
      iris << link('wikipedia')&.dig('@id')
      iris << external_id('wikidata')&.then { |id| "http://www.wikidata.org/entity/#{id}" }
      iris << external_id('isni')&.then { |id| "https://isni.org/isni/#{id.delete(' ')}" }
      iris << external_id('fundref')&.then { |id| "https://doi.org/10.13039/#{id}" }
      iris.compact.map { |iri| { '@id' => iri } }
    end

    def external_id(type)
      external = Array(@record['external_ids']).detect { |ids| ids['type'] == type }
      return nil unless external

      external['preferred'].presence || Array(external['all']).first
    end

    def locations
      Array(@record['locations']).map do |location|
        details = location['geonames_details'] || {}
        place = {
          '@type' => 'Place',
          'name' => details['name'],
          'address' => {
            '@type' => 'PostalAddress',
            'addressLocality' => details['name'],
            'addressRegion' => details['country_subdivision_name'],
            'addressCountry' => details['country_code']
          }.compact
        }
        place['@id'] = "https://sws.geonames.org/#{location['geonames_id']}/" if location['geonames_id']
        if details['lat'] && details['lng']
          place['geo'] = { '@type' => 'GeoCoordinates', 'latitude' => details['lat'], 'longitude' => details['lng'] }
        end
        place.compact
      end
    end

    def relationships
      Array(@record['relationships']).each_with_object({}) do |relationship, properties|
        property = RELATIONSHIPS[relationship['type']]
        next unless property

        (properties[property] ||= []) << { '@id' => relationship['id'], 'name' => relationship['label'] }.compact
      end
    end
  end
end
