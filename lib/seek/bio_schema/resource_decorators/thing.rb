module Seek
  module BioSchema
    module ResourceDecorators
      # Represents attributes related to schema.org Thing. Not expected to be used directly, but provides the default
      # attributes for all other types that subclass Thing.
      class Thing < BaseDecorator
        schema_mappings description: :description,
                        title: :name,
                        url: :url,
                        keywords: :keywords

        def url
          identifier
        end

        # the rdf indentifier for the resource, which is its URL
        def identifier
          rdf_resource
        end

        # If the resource has an avatar, then returns the image url
        def image
          return unless resource.avatar
          "#{Seek::Config.site_base_host}/#{resource.class.table_name}" \
            "/#{resource.id}/avatars/#{resource.avatar.id}?size=250"
        end

        # list of comma seperated tags, it the resource supports it
        def keywords
          tags_as_text_array.join(', ') if resource.respond_to?(:tags_as_text_array)
        end

        def date_created
          resource.created_at&.iso8601 if resource.respond_to?(:created_at)
        end

        def date_modified
          resource.updated_at&.iso8601 if resource.respond_to?(:updated_at)
        end
      end
    end
  end
end
