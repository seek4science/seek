module Seek
  module Samples
    module AttributeTypeHandlers
      class FloatAttributeHandler < BaseAttributeHandler
        def test_value(value)
          Float(value)
        end
      end
    end
  end
end
