module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataCatalogue
      class DataCatalogue < Thing

        def rdf_resource
          nil
        end

        def schema_type
          'DataCatalogue'
        end


      end
    end
  end
end
