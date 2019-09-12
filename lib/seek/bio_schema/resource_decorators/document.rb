module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class Document < CreativeWork

        def content_type
          resource.content_blob.content_type
        end

        def schema_type
          'DigitalDocument'
        end

      end
    end
  end
end
