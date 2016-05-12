module Seek
  module Samples
    module AttributeTypeHandlers
      class FloatAttributeTypeHandler < BaseAttributeHandler
        def test_value(value)
          Float(value)
        end
      end
    end
  end
end
