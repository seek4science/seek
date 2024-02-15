module Seek
  module Samples
    module AttributeHandlers
      class AttributeHandlerFactory
        include Singleton

        attr_accessor :handlers

        def initialize
          @handlers = {}
        end

        def for_attribute(attribute)
          "Seek::Samples::AttributeHandlers::#{attribute.sample_attribute_type.base_type}AttributeHandler".constantize.new(attribute)
        rescue NameError
          raise UnrecognisedAttributeHandler, "unrecognised attribute base type '#{attribute.sample_attribute_type.base_type}'"
        end
      end

      class UnrecognisedAttributeHandler < RuntimeError; end
    end
  end
end
