module Seek
  module Samples
    module AttributeTypeHandlers
      class ListAttributeTypeHandler < BaseAttributeHandler
        class MissingControlledVocabularyException < AttributeHandlerException; end

        def test_value(array_value)

          if !array_value.is_a?(Array)
            fail "'#{array_value}' is not an array" unless array_value.is_a?(Array)
          else
            array_value.each do |value|
              fail "'#{value}' is not included in the controlled vocabulary" unless controlled_vocab.includes_term?(value) || controlled_vocab.custom_input
            end
          end
        end
        private

        def controlled_vocab
          vocab = additional_options[:controlled_vocab]
          fail MissingControlledVocabularyException.new unless vocab
          vocab
        end
      end
    end
  end
end
