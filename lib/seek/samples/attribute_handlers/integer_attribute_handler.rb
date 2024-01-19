module Seek
  module Samples
    module AttributeHandlers
      class IntegerAttributeHandler < BaseAttributeHandler
        def test_value(value)
          raise 'Not an integer' unless Integer(value.to_f) # the to_f is to allow "1.0" type numbers
          raise 'Not an integer' unless (Float(value) % 1).zero?
        end

        def convert(value)
          int_value = Integer(value, exception: false) if value.is_a?(String)
          int_value.nil? ? value : int_value
        end

      end
    end
  end
end
