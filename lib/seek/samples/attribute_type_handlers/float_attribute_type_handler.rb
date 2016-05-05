module Seek
  module Samples
    module AttributeTypeHandlers
      class FloatAttributeTypeHandler < BaseAttributeHandler
        def test_value(value,*args)
          fail 'Not a float' unless Float(value).to_s == value.to_s || Integer(value).to_s == value.to_s
        end
      end
    end
  end
end
