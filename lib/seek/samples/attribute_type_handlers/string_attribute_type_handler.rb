module Seek
  module Samples
    module AttributeTypeHandlers
      class StringAttributeTypeHandler < BaseAttributeHandler
        def test_value(value)
          fail 'Not a string' unless value.is_a?(String)
        end
      end
    end
  end
end
