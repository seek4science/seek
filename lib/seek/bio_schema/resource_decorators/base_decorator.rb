module Seek
  module BioSchema
    module ResourceDecorators
      # Base Decorator that provides the underlying behaviour, and common features, for all Decorators.
      # The Decorator is an extension to the resource that provided or alters the properties of that resource
      # for Schema.org (Bioschemas.org)
      class BaseDecorator
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        def context
          'http://schema.org'
        end

        def schema_type
          @resource.class.name
        end

        def image
          return unless resource.avatar
          "#{Seek::Config.site_base_host}/#{resource.class.table_name}" \
            "/#{resource.id}/avatars/#{resource.avatar.id}?size=250"
        end

        def identifier
          rdf_resource
        end

        def mini_definition
          {
            '@type': schema_type,
            '@id': identifier,
            'name': title
          }
        end

        instance_eval do
          private

          def associated_items(pairs)
            pairs.each do |method, collection|
              define_method(method) do
                mini_definitions(send(collection))
              end
            end
          end
        end

        private

        def mini_definitions(collection)
          collection.collect do |item|
            Factory.instance.get(item).mini_definition
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
