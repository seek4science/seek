module Seek
  module Samples
    module AttributeTypeHandlers
      class BaseAttributeHandler
        def convert(value)
          value
        end

        def validate_value(value,*args)
          begin
            test_value(value,*args)
          rescue
            return false
          end
          true
        end
      end
    end
  end
end
