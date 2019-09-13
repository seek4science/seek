module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class CreativeWork < Thing

        associated_items provider: :projects,
                         creator: :creators

        schema_mappings license: :license,
                        creator: :creator,
                        provider: :provider,
                        created_at: :dateCreated,
                        updated_at: :dateModified,
                        content_type: :encodingFormat

        # list of comma seperated tags, it the resource supports it
        def keywords
          tags_as_text_array.join(", ") if resource.respond_to?(:tags_as_text_array)
        end

        def content_type
          if resource.respond_to?(:content_blob) && resource.content_blob
            resource.content_blob.content_type
          end
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
