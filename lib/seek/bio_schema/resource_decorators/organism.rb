module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Organism
      class Organism < Thing
        schema_mappings synonyms: :alternateName,
                        ncbi_uri: :sameAs

        TAXON_PROFILE = 'https://bioschemas.org/profiles/Taxon/1.0-RELEASE'.freeze

        def synonyms
          if concept && concept[:synonyms]
            concept[:synonyms]
          else
            []
          end
        end

        def schema_type
          'Taxon'
        end

        def conformance
          TAXON_PROFILE
        end
      end
    end
  end
end
