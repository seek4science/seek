module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Document
      class Document < CreativeWork
        def schema_type
          'DigitalDocument'
        end
      end
    end
  end
end
