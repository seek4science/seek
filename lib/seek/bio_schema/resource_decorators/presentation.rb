module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class Presentation < Seek::BioSchema::ResourceDecorators::Document
        def schema_type
          'PresentationDigitalDocument'
        end
      end
    end
  end
end
