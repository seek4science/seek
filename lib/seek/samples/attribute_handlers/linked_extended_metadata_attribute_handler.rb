module Seek
  module Samples
    module AttributeHandlers
      class LinkedExtendedMetadataAttributeHandler < BaseAttributeHandler
        class MissingLinkedExtendedMetadataException < AttributeHandlerException; end

        def test_value(value)
          fail 'Not a extended metadata' unless value.is_a?(Hash)
        end

        def convert(value)
          data = Seek::JSONMetadata::Data.new(linked_extended_metadata_type)
          data.mass_assign(value)
          data
        end

        private

        def linked_extended_metadata_type
          linked_extended_metadata_type = attribute.linked_extended_metadata_type
          raise MissingLinkedExtendedMetadataException unless linked_extended_metadata_type

          linked_extended_metadata_type
        end
      end
    end
  end
end