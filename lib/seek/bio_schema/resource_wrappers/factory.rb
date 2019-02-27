module Seek
  module BioSchema
    module ResourceWrappers
      class Factory
        include Singleton

        def initialize
          @wrapper_classes = {}
        end

        def get(resource)
          type = resource.class
          unless resource.schema_org_supported?
            raise UnsupportedTypeException, "Bioschema not supported for #{type.name}"
          end

          wrapper_class(type).new(resource)
        end

        private

        attr_reader :wrapper_classes

        def wrapper_class(type)
          @wrapper_classes[type] ||
            @wrapper_classes[type] = "Seek::BioSchema::ResourceWrappers::#{type.name}".constantize
        end
      end
    end
  end
end
