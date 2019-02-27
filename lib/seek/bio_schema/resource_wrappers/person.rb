module Seek
  module BioSchema
    module ResourceWrappers
      class Person < ResourceWrapper
        def url
          web_page.blank? ? identifier : web_page
        end

        def member_of
          projects.collect do |project|
            Factory.instance.get(project).mini
          end
        end
      end
    end
  end
end
