module Seek
  module Samples
    module AttributeTypeHandlers
      class BooleanAttributeTypeHandler < BaseAttributeHandler
        def initialize(additional_options)
          super(additional_options)
          @conversion_map = { '1' => true, '0' => false, 'true' => true, 'false' => false }
        end

        def test_value(value)
          raise 'Not a boolean' unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        end

        def test_blank?(value)
          super && !value.is_a?(FalseClass)
        end

        def convert(value)
          if !(value.is_a?(TrueClass) || value.is_a?(FalseClass)) && @conversion_map.keys.include?(value&.downcase)
            value = @conversion_map[value.downcase]
          end
          value
        end
      end
    end
  end
end
