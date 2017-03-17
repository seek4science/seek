module Seek
  module Samples
    module AttributeTypeHandlers
      class AttributeHandlerException < Exception; end
      class BaseAttributeHandler
        def initialize(additional_options = {})
          self.additional_options = additional_options
        end

        def convert(value)
          value
        end

        def validate_value?(value)
          begin
            test_value(value)
          rescue AttributeHandlerException => e
            raise e
          rescue
            return false
          end
          true
        end

        private

        def convert_value(value)
          value
        end

        attr_accessor :additional_options
      end
    end
  end
end
