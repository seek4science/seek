module Seek
  module Samples
    module AttributeTypeHandlers
      class CVAttributeTypeHandler < BaseAttributeHandler
        class MissingControlledVocabularyException < AttributeHandlerException; end

        def test_value(value)
          fail "'#{value}' is not included in the controlled vocabulary" unless controlled_vocab.includes_term?(value)
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
