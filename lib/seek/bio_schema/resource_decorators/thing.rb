module Seek
  module BioSchema
    module ResourceDecorators
      class Thing < BaseDecorator

        associated_items subject_of: :events

        schema_mappings description: :description,
                        title: :name,
                        url: :url,
                        keywords: :keywords,
                        subject_of: :subjectOf

        def url
          identifier
        end

      end
    end
  end
end