module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a creator
      class PublicationAuthor < Thing
        PERSON_PROFILE = 'https://bioschemas.org/profiles/Person/0.2-DRAFT-2019_07_19/'.freeze

        schema_mappings first_name: :givenName,
                        last_name: :familyName

        def conformance
          PERSON_PROFILE
        end

        def schema_type
          'Person'
        end

        def title
          name
        end

        def rdf_resource
          RDF::Resource.new(identifier)
        end

        def identifier
          if person
            resource_url(person)
          else
            ROCrate::Person.format_id(name)
          end
        end
      end
    end
  end
end
