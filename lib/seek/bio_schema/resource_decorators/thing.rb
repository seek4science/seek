module Seek
  module BioSchema
    module ResourceDecorators
      # Represents attributes related to schema.org Thing. Not expected to be used directly, but provides the default
      # attributes for all other types that subclass Thing.
      class Thing < BaseDecorator
        schema_mappings description: :description,
                        title: :name,
                        url: :url,
                        image: :image,
                        keywords: :keywords

        def url
          identifier
        end

        # the rdf identifier for the resource, which is its URL
        def identifier
          rdf_resource.to_s
        end

        # If the resource has an avatar, then returns the image url
        def image
          return unless resource.respond_to?(:avatar)
          return if resource.avatar.blank?

          polymorphic_url([resource, resource.avatar], size: 250, **Seek::Config.site_url_options)
        end

        # list of comma seperated tags, it the resource supports it
        def keywords
          obj = resource.is_a_version? ? resource.parent : resource
          obj.tags_as_text_array.join(', ') if obj.respond_to?(:tags_as_text_array)
        end
        
      end
    end
  end
end
