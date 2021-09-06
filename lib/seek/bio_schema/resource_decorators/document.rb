module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Document
      class Document < CreativeWork
        include ActionView::Helpers::NumberHelper

        def schema_type
          'DigitalDocument'
        end

        def conformance
          'https://schema.org/DigitalDocument'
        end
      end
    end
  end
end
