module Seek
  module BioSchema
    module ResourceWrappers
      class Project < ResourceWrapper
        def url
          web_page.blank? ? identifier : web_page
        end

        def member
          people.collect do |person|
            Factory.instance.get(person).mini
          end
        end

        def schema_type
          'Organization'
        end
      end
    end
  end
end
