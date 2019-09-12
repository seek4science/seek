module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Project
      class Project < BaseDecorator
        associated_items member: :people

        def url
          web_page.blank? ? identifier : web_page
        end

        def schema_type
          'Project'
        end
      end
    end
  end
end
