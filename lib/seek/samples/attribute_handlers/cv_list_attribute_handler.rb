module Seek
  module Samples
    module AttributeHandlers
      class CVListAttributeHandler < CVAttributeHandler
        def test_value(array_value)
          array_value.each do |value|
            unless allow_cv_free_text? || controlled_vocab.includes_term?(value)
              raise "'#{value}' is not included in the controlled vocabulary"
            end
          end
        end

        def convert(value)
          value = value.split(',').collect(&:strip) if value.is_a?(String)
          value.compact_blank
        end
      end
    end
  end
end
