module Seek
  module Samples
    module AttributeTypeHandlers
      class CVListAttributeTypeHandler < CVAttributeTypeHandler
        def test_value(array_value)
          array_value.each do |value|
            unless controlled_vocab.includes_term?(value) || controlled_vocab.custom_input
              raise "'#{value}' is not included in the controlled vocabulary"
            end
          end
        end

        def convert(value)
          value.compact_blank
        end
      end
    end
  end
end
