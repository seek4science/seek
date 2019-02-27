module Seek
  module BioSchema
    module ResourceWrappers
      class Project < ResourceWrapper
        relationships member: :people

        def url
          web_page.blank? ? identifier : web_page
        end

        def schema_type
          'Organization'
        end
      end
    end
  end
end
