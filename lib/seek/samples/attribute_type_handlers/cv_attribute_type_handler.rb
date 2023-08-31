module Seek
  module Samples
    module AttributeTypeHandlers
      class CVAttributeTypeHandler < BaseAttributeHandler
        class MissingControlledVocabularyException < AttributeHandlerException; end

        def test_value(value)
          unless controlled_vocab.custom_input? || controlled_vocab.includes_term?(value)
            raise "'#{value}' is not included in the controlled vocabulary"
          end
        end

        def convert(value)
          return value if value.is_a?(String)

          value.compact_blank.first
        end

        private

        def controlled_vocab
          vocab = additional_options[:controlled_vocab]
          raise MissingControlledVocabularyException unless vocab

          vocab
        end
      end
    end
  end
end
