module Seek
  module Samples
    module AttributeHandlers
      class FloatAttributeHandler < BaseAttributeHandler
        def test_value(value)
          Float(value)
        end
      end
    end
  end
end
