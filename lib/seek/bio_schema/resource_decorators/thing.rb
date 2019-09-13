module Seek
  module BioSchema
    module ResourceDecorators
      class Thing < BaseDecorator


        schema_mappings description: :description,
                        title: :name,
                        url: :url,
                        keywords: :keywords,
                        subject_of: :subjectOf

        def url
          identifier
        end

        def subject_of
          events if self.respond_to?(:events)
        end
      end
    end
  end
end
