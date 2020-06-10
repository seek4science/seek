module Seek
  module BioSchema
    module ResourceDecorators
      class Collection < CreativeWork
        associated_items has_part: :assets
        schema_mappings has_part: :hasPart

        def schema_type
          'Collection'
        end
      end
    end
  end
end
