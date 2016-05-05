module Seek
  module Samples
    module AttributeTypeHandlers
      class CVAttributeTypeHandler < BaseAttributeHandler
        def test_value(value,*args)
          options = args.extract_options!
          vocab = options[:controlled_vocab]
          fail "'#{value}' is not included in the controlled vocabulary" unless vocab.labels.include?(value)
        end
      end
    end
  end
end
