module Seek
  module JSONMetadata
    METHOD_PREFIX = '__metadata_attribute_'

    module Serialization

      extend ActiveSupport::Concern

      included do
        self.before_validation :update_json_metadata
      end

      # Mass assignment of attributes
      def data=(hash)
        data.mass_assign(hash)
      end

      def data
        @data ||= Seek::JSONMetadata::Data.new(metadata_type, json_metadata)
      end

      def get_attribute_value(attr)
        attr = attr.accessor_name if attr.is_a?(attribute_class)

        data[attr.to_s]
      end

      def set_attribute_value(attr, value)
        attr = attr.accessor_name if attr.is_a?(attribute_class)

        data[attr] = value
      end

      def blank_attribute?(attr)
        attr = attr.accessor_name if attr.is_a?(attribute_class)

        data[attr].blank? || (data[attr].is_a?(Hash) && data[attr]['id'].blank? && data[attr]['title'].blank?)
      end

      def update_json_metadata
        self.json_metadata = data.to_json
      end

      def respond_to_missing?(method_name, include_private = false)
        name = method_name.to_s
        if metadata_type.try(:attribute_by_method_name, name.chomp('=')).present?
          true
        else
          super
        end
      end

      def method_missing(method_name, *args)
        name = method_name.to_s
        if (attribute = metadata_type.attribute_by_method_name(name.chomp('='))).present?
          setter = name.end_with?('=')
          attribute_name = attribute.accessor_name
          if data.key?(attribute_name)
            set_attribute_value(attribute_name, args.first) if setter
            get_attribute_value(attribute_name)
          else
            super
          end
        else
          super
        end
      end

      def attribute_class
        raise 'Needs overriding to provide the class of the metadata attribute'
      end

    end

  end
end