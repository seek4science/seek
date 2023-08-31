module Seek
  module BioSchema
    module ResourceDecorators
      # Base Decorator that provides the underlying behaviour, and common features, for all Decorators.
      # The Decorator is an extension to the resource that provided or alters the properties of that resource
      # for Schema.org (Bioschemas.org)
      class BaseDecorator
        include ActionView::Helpers::SanitizeHelper
        include Seek::Util.routes

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

        # The @context to be used for the JSON-LD
        def context
          Seek::BioSchema::Serializer::SCHEMA_ORG
        end

        # The schema.org @type .
        # defaults to the resource class name, but can be overridden
        def schema_type
          @resource.class.name
        end

        def rdf_resource
          uri = resource_url(resource)
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

        def reference
          { '@id': identifier.to_s }
        end

        def resource_url(resource, opts = {})
          strip_version = opts.delete(:strip_version)
          opts.reverse_merge!(Seek::Config.site_url_options)
          resource = Array(resource).map do |r|
            if r.respond_to?(:is_a_version?) && r.is_a_version?
              opts[:version] = r.version unless strip_version
              r.parent
            else
              r
            end
          end

          polymorphic_url(resource, opts)
        end

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
                mini_definitions(send(collection)) if respond_to?(collection)
              end
            end
          end

          # used to define the mapping between the method to be call, and the property
          # for e.g
          #   schema_mappings doi: :identifier
          # calls the method 'doi' on the decorator, and then the value will be used with the schema.org property
          # 'identifier'. Multiple mappings can be provided, separated with a comma.
          # The method defined, could also be a method defined with 'assocated_items'
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
          return [] if collection.empty?

          mini_col = []
          collection.each do |item|
            next if item.respond_to?(:public?) && !item.public?

            mini_col << Seek::BioSchema::ResourceDecorators::Factory.instance.get(item).mini_definition
          end
          mini_col
        end

        def respond_to_missing?(name, include_private = false)
          resource.respond_to?(name,
                               include_private) || resource.is_a_version? && resource.parent.respond_to?(name,
                                                                                                         include_private)
        end

        def method_missing(method, *args, &block)
          if resource.respond_to?(method)
            resource.send(method, *args, &block)
          elsif resource.is_a_version? && resource.parent.respond_to?(method)
            resource.parent.send(method, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
