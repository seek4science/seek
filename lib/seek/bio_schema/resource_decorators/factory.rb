module Seek
  module BioSchema
    module ResourceDecorators
      # Factory that can 'get' a Decorator for a given resource
      class Factory
        include Singleton

        def initialize
          @decorator_classes = {}
        end

        # get the Decorator for the given resource, throws an UnsupportedTypeException if that resource isn't supported
        def get(resource)
          type = resource.class
          unless resource.schema_org_supported?
            raise UnsupportedTypeException, "Bioschema not supported for #{type.name}"
          end

          decorator_class(type).new(resource)
        end

        private

        def decorator_class(type)
          @decorator_classes[type] ||
            @decorator_classes[type] = "Seek::BioSchema::ResourceDecorators::#{type.name}".constantize
        end
      end
    end
  end
end
