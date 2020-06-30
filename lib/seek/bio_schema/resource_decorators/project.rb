module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Project
      class Project < Thing
        associated_items member: :people

        schema_mappings image: :logo,
                        member: :member

        def url
          web_page.blank? ? identifier : web_page
        end

        def schema_type
          %w[Project Organization]
        end
      end
    end
  end
end
