module Seek
  module Samples
    module AttributeTypeHandlers
      class BooleanAttributeTypeHandler < BaseAttributeHandler
        def initialize
          @conversion_map = { '1' => true, '0' => false, 'true' => true, 'false' => false }
        end

        def test_value(value)
          fail 'Not a boolean' unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        end

        def convert(value)
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
            if @conversion_map.keys.include?(value.downcase)
              value = @conversion_map[value.downcase]
            end
          end
          value
        end
      end
    end
  end
end
