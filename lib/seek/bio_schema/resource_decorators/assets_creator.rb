module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a creator
      class AssetsCreator < Thing
        PERSON_PROFILE = 'https://bioschemas.org/profiles/Person/0.3-DRAFT'.freeze

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

        def rdf_resource
          RDF::Resource.new(identifier)
        end

        def identifier
          if creator
            resource_url(creator)
          elsif orcid
            orcid
          else
            ROCrate::Person.format_id(name)
          end
        end
      end
    end
  end
end
