module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataCatalogue
      class DataCatalog < Thing
        schema_mappings date_created: :dateCreated,
                        provider: :provider

        def rdf_resource
          nil
        end

        def schema_type
          'DataCatalog'
        end

        def url
          resource.url
        end

        def keywords
          resource.keywords
        end
      end
    end
  end
end
