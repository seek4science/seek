module Seek
  module Samples
    module AttributeTypeHandlers
      class ListAttributeTypeHandler < BaseAttributeHandler
        class MissingControlledVocabularyException < AttributeHandlerException; end

        #todo check if values in Array are controlled_vocab terms
        def test_value(value)
          fail "'#{value}' is not an array" unless value.is_a?(Array)
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
