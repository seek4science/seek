module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class CreativeWork < Thing

        associated_items provider: :projects
        associated_items creator: :creators

        # list of comma seperated tags, it the resource supports it
        def keywords
          tags_as_text_array.join(", ") if resource.respond_to?(:tags_as_text_array)
        end

        def license
          if resource.license
            license = Seek::License.find(resource.license)
            if license
              license.url
            end
          end
        end

      end
    end
  end
end
