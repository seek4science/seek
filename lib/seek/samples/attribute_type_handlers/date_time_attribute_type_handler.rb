module Seek
  module Samples
    module AttributeTypeHandlers
      class DateTimeAttributeTypeHandler < BaseAttributeHandler
        def test_value(value,*args)
          fail 'Not a date time' unless DateTime.parse(value.to_s)
        end
      end
    end
  end
end
