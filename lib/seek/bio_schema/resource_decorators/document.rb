module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Document
      class Document < CreativeWork
        associated_items subject_of: :events

        def schema_type
          'DigitalDocument'
        end
      end
    end
  end
end
