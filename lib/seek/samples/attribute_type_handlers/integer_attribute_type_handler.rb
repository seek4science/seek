module Seek
  module Samples
    module AttributeTypeHandlers
      class IntegerAttributeTypeHandler < BaseAttributeHandler
        def test_value(value,*args)
          fail 'Not an integer' unless (Integer(value).to_s == value.to_s)
        end
      end
    end
  end
end
