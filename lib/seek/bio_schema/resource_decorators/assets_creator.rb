module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a creator
      class AssetsCreator < Thing
        PERSON_PROFILE = 'https://bioschemas.org/profiles/Person/0.2-DRAFT-2019_07_19/'.freeze

        schema_mappings given_name: :givenName,
                        family_name: :familyName,
                        orcid: :orcid,
                        affiliation: :worksFor

        def conformance
          PERSON_PROFILE
        end

        def schema_type
          'Person'
        end

        def url
          if orcid
            orcid
          elsif creator
            resource_url(creator)
          else
            nil
          end
        end

        def rdf_resource
          RDF::Resource.new(identifier)
        end

        def identifier
          url || ROCrate::Person.format_id(name)
        end
      end
    end
  end
end
