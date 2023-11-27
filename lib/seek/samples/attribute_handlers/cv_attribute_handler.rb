module Seek
  module Samples
    module AttributeHandlers
      class CVAttributeHandler < BaseAttributeHandler
        class MissingControlledVocabularyException < AttributeHandlerException; end

        def test_value(value)
          unless allow_cv_free_text? || controlled_vocab.includes_term?(value)
            raise "'#{value}' is not included in the controlled vocabulary"
          end
        end

        def convert(value)
          return value if value.is_a?(String)

          value.compact_blank.first
        end

        private

        delegate :allow_cv_free_text?, to: :attribute

        def controlled_vocab
          vocab = attribute.sample_controlled_vocab
          raise MissingControlledVocabularyException unless vocab

          vocab
        end
      end
    end
  end
end
