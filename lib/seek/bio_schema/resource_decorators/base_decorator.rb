module Seek
  module BioSchema
    module ResourceDecorators
      # Base Decorator that provides the underlying behaviour, and common features, for all Decorators.
      # The Decorator is an extension to the resource that provided or alters the properties of that resource
      # for Schema.org (Bioschemas.org)
      class BaseDecorator
        include ActionView::Helpers::SanitizeHelper
        include Rails.application.routes.url_helpers

        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        def mappings
          [[:identifier, '@id']]
        end

        def attributes
          mappings.collect do |method, property|
            Seek::BioSchema::BioSchemaAttribute.new(method, property)
          end
        end

        # list of comma seperated tags, it the resource supports it
        def keywords
          tags_as_text_array.join(', ') if resource.respond_to?(:tags_as_text_array)
        end

        # The @context to be used for the JSON-LD
        def context
          'http://schema.org'
        end

        # The schema.org @type .
        # defaults to the resource class name, but can be overridden
        def schema_type
          @resource.class.name
        end

        # If the resource has an avatar, then returns the image url
        def image
          return unless resource.avatar
          "#{Seek::Config.site_base_host}/#{resource.class.table_name}" \
            "/#{resource.id}/avatars/#{resource.avatar.id}?size=250"
        end

        # the rdf indentifier for the resource, which is its URL
        def identifier
          rdf_resource
        end

        def rdf_resource
          uri = polymorphic_url(resource, host: Seek::Config.site_base_host)
          RDF::Resource.new(uri).to_s
        end

        # the minimal definition for the resource, used mainly for associated items
        # by default this includes just @type, @id, and name, but can be extended in the subclass if necessary
        def mini_definition
          {
            '@type': schema_type,
            '@id': identifier,
            'name': sanitize(title)
          }
        end

        def json_ld; end

        instance_eval do
          private

          # to be used to easily define a method that relates to a property and handles a collection.
          # To be used within the Decorator class to define the method name, and the collection to be used.
          # This results in an array of Hash objects containing the minimal definition JSON. For example
          #   associated_items member: :people
          #   create a method 'member' that returns a collection of Hash objects containing the
          #   minimal definition for each item resulting from calling 'people' on the resource
          def associated_items(**pairs)
            pairs.each do |method, collection|
              define_method(method) do
                mini_definitions(send(collection))
              end
            end
          end

          def schema_mappings(**pairs)
            mappings = pairs.collect do |method, property|
              [method, property]
            end
            define_method(:mappings) do
              super() | mappings
            end
          end
        end

        private

        def mini_definitions(collection)
          return if collection.empty?
          collection.collect do |item|
            Seek::BioSchema::ResourceDecorators::Factory.instance.get(item).mini_definition
          end
        end

        def respond_to_missing?(name, include_private = false)
          resource.respond_to?(name, include_private)
        end

        def method_missing(method, *args, &block)
          if resource.respond_to?(method)
            resource.send(method, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
