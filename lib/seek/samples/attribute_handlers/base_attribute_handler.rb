module Seek
  module Samples
    module AttributeHandlers
      class AttributeHandlerException < RuntimeError; end

      class BaseAttributeHandler
        def initialize(attribute)
          @attribute = attribute
        end

        def convert(value)
          value
        end

        # whether the value is considered blank when full filling being required
        def test_blank?(value)
          value.blank?
        end

        def validate_value?(value)
          begin
            test_value(value)
          rescue AttributeHandlerException => e
            raise e
          rescue StandardError
            return false
          end
          true
        end

        private

        attr_reader :attribute
      end
    end
  end
end
