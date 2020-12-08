module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Human Disease
      class HumanDisease < Thing
        schema_mappings synonyms: :alternateName,
                        ncbi_uri: :sameAs

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
      end
    end
  end
end
