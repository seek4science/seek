module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class Publication < CreativeWork
        include ActionView::Helpers::NumberHelper

        def schema_type
          'CreativeWork'
        end

        def assets_creators
          publication_authors
        end
      end
    end
  end
end
