module Seek
  module Samples
    module AttributeTypeHandlers
      class LinkedCustomMetadataAttributeTypeHandler < BaseAttributeHandler

        def test_value(value)
          fail 'Not a custom metadata' unless value.is_a?(CustomMetadata)
        end
      end
    end
  end
end