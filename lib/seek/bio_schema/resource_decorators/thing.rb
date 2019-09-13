module Seek
  module BioSchema
    module ResourceDecorators
      class Thing < BaseDecorator


        schema_mappings description: :description,
                        title: :name,
                        url: :url,
                        keywords: :keywords

        def url
          identifier
        end

      end
    end
  end
end
