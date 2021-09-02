module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Document
      class Document < CreativeWork
        include ActionView::Helpers::NumberHelper

        associated_items part_of: :collections

        schema_mappings part_of: :isPartOf
        
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
