module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Person
      class Person < Thing
        associated_items member_of: :projects

        def url
          web_page.blank? ? identifier : web_page
        end
      end
    end
  end
end
