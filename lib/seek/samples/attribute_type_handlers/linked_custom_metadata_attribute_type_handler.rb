module Seek
  module Samples
    module AttributeTypeHandlers
      class LinkedCustomMetadataAttributeTypeHandler < BaseAttributeHandler
        class MissingLinkedCustomMetadataTypeException < AttributeHandlerException; end

        def test_value(value)
          fail 'Not a custom metadata' unless value.is_a?(Hash)
        end

        def convert(value)
          data = Seek::JSONMetadata::Data.new(linked_custom_metadata_type)
          data.mass_assign(value)
          data
        end

        private

        def linked_custom_metadata_type
          linked_custom_metadata_type = additional_options[:linked_custom_metadata_type]
          raise MissingLinkedCustomMetadataTypeException unless linked_custom_metadata_type

          linked_custom_metadata_type
        end
      end
    end
  end
end