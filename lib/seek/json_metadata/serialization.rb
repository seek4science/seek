module Seek
  module JsonMetadata
    module Serialization
      extend ActiveSupport::Concern

      included do
        before_validation :update_json_metadata
      end

      # Mass assignment of attributes
      def data=(hash)
        json_metadata_will_change!
        data.mass_assign(hash)
      end

      def data
        @data ||= Seek::JsonMetadata::Data.new(metadata_type, json_metadata)
      end

      def get_attribute_value(attr)
        attr = attr.accessor_name if attr.is_a?(attribute_class)
        data[attr.to_s]
      end

      def set_attribute_value(attr, value)
        json_metadata_will_change!
        attr = attr.accessor_name if attr.is_a?(attribute_class)

        data[attr] = value
      end

      def update_json_metadata
        self.json_metadata = data.to_json
      end

      def attribute_class
        raise 'Needs overriding to provide the class of the metadata attribute'
      end
    end
  end
end
