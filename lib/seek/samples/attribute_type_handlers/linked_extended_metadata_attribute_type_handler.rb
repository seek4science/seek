module Seek
  module Samples
    module AttributeTypeHandlers
      class LinkedExtendedMetadataAttributeTypeHandler < BaseAttributeHandler
        class MissingLinkedExtendedMetadataTypeException < AttributeHandlerException; end

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
          linked_extended_metadata_type = additional_options[:linked_extended_metadata_type]
          raise MissingLinkedExtendedMetadataTypeException unless linked_extended_metadata_type

          linked_extended_metadata_type
        end
      end
    end
  end
end