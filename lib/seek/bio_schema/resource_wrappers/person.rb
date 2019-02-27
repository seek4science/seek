module Seek
  module BioSchema
    module ResourceWrappers
      class Person < ResourceWrapper
        relationships member_of: :projects

        def url
          web_page.blank? ? identifier : web_page
        end

        # def member_of
        #   minis(projects)
        # end
      end
    end
  end
end
