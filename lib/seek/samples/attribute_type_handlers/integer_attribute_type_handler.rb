module Seek
  module Samples
    module AttributeTypeHandlers
      class IntegerAttributeTypeHandler < BaseAttributeHandler
        def test_value(value)
          fail 'Not an integer' unless Integer(value.to_f) # the to_f is to allow "1.0" type numbers
          fail 'Not an integer' unless Float(value) % 1 == 0
        end
      end
    end
  end
end
