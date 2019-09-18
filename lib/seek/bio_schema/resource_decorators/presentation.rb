module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Presentation
      class Presentation < Seek::BioSchema::ResourceDecorators::Document
        def schema_type
          'PresentationDigitalDocument'
        end
      end
    end
  end
end
