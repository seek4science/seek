module Seek
  module Samples
    module AttributeTypeHandlers
      class AttributeTypeHandlerFactory
        include Singleton

        attr_accessor :handlers

        def initialize
          @handlers = {}
        end

        def for_base_type(base_type)
          return handlers[base_type] if handlers[base_type]
          begin
            handlers[base_type] = "Seek::Samples::AttributeTypeHandlers::#{base_type}AttributeTypeHandler".constantize.new
          rescue NameError
            raise UnrecognisedAttributeHandlerType.new("unrecognised attribute base type '#{base_type}'")
          end
        end
      end

      class UnrecognisedAttributeHandlerType < Exception; end
    end
  end
end
