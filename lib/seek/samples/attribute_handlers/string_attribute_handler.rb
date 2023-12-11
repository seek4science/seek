module Seek
  module Samples
    module AttributeHandlers
      class StringAttributeHandler < BaseAttributeHandler
        def test_value(value)
          raise 'Not a string' unless value.is_a?(String)
        end
      end
    end
  end
end
