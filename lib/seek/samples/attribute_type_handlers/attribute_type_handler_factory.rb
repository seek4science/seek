module Seek
  module Samples
    module AttributeTypeHandlers
      class AttributeTypeHandlerFactory
        include Singleton

        attr_accessor :handlers

        def initialize
          @handlers = {}
        end

        def for_base_type(attribute)
          "Seek::Samples::AttributeTypeHandlers::#{attribute.sample_attribute_type.base_type}AttributeTypeHandler".constantize.new(attribute)
        rescue NameError
          raise UnrecognisedAttributeHandlerType, "unrecognised attribute base type '#{attribute.sample_attribute_type.base_type}'"
        end
      end

      class UnrecognisedAttributeHandlerType < RuntimeError; end
    end
  end
end
