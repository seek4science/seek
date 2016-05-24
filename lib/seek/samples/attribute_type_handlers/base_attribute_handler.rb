module Seek
  module Samples
    module AttributeTypeHandlers
      class AttributeHandlerException < Exception; end
      class BaseAttributeHandler
        def convert(value)
          value
        end

        def validate_value?(value, additional_options = {})
          begin
            self.additional_options = additional_options
            test_value(value)
          rescue AttributeHandlerException => e
            raise e
          rescue
            return false
          end
          true
        end

        private

        attr_accessor :additional_options
      end
    end
  end
end
