module Seek
  module Samples
    module AttributeTypeHandlers
      class AttributeTypeHandlerFactory
        include Singleton

        attr_accessor :handlers

        def initialize
          @handlers = {}
        end

        def for_base_type(base_type, additional_options = {})
          key = [base_type, additional_options]
          return handlers[key] if handlers[key]
          begin
            handlers[key] = "Seek::Samples::AttributeTypeHandlers::#{base_type}AttributeTypeHandler".constantize.new(additional_options)
          rescue NameError
            raise UnrecognisedAttributeHandlerType.new("unrecognised attribute base type '#{base_type}'")
          end
        end
      end

      class UnrecognisedAttributeHandlerType < Exception; end
    end
  end
end
