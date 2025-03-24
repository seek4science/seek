module Seek
  module Samples
    module AttributeHandlers
      class FloatAttributeHandler < BaseAttributeHandler
        def test_value(value)
          Float(value)
        end

        def convert(value)
          float_value = Float(value, exception: false) if value.is_a?(String)
          float_value.nil? ? value : float_value
        end

      end
    end
  end
end
