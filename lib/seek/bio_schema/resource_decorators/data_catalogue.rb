module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataCatalogue
      class DataCatalogue < Thing

        schema_mappings date_created: :dateCreated,
                        provider: :provider

        def rdf_resource
          nil
        end

        def schema_type
          'DataCatalogue'
        end

        def url
          resource.url
        end


      end
    end
  end
end
