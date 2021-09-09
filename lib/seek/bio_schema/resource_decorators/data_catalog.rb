module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataCatalogue
      class DataCatalog < Thing
        schema_mappings created_at: :dateCreated,
                        updated_at: :dateModified,
                        provider: :provider

        DATACATALOG_PROFILE = 'https://bioschemas.org/profiles/DataCatalog/0.3-RELEASE-2019_07_01/'

        def rdf_resource
          nil
        end

        def schema_type
          'DataCatalog'
        end

        def conformance
          DATACATALOG_PROFILE
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
