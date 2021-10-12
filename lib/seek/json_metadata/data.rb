module Seek
  module JSONMetadata
    class Data < HashWithIndifferentAccess
      class InvalidKeyException < RuntimeError; end

      attr_accessor :sample_type

      delegate :metadata_attributes, to: :sample_type

      def initialize(sample_type = nil, json = nil)
        if sample_type
          @sample_type = sample_type
          if json.blank?
            initialize_structure
          else
            update(JSON.parse(json))
          end
        end
      end

      # Pre-processes the value before setting
      alias orig_set_value []=

      def []=(key, value)
        super(key, pre_process_value(key, value))
      end

      # Mass assign values provided as a hash. Pre-processes by default, but can be avoided by passing `pre_process: false`
      def mass_assign(hash, pre_process: true)
        method = pre_process ? :[]= : :orig_set_value
        validate_hash(hash)
        hash.each do |key, value|
          send(method, key, value)
        end
      end

      private

      def validate_hash(hash)
        attribute_keys = metadata_attributes.collect(&:accessor_name)
        provided_keys = hash.keys.collect(&:to_s)
        wrong = provided_keys - attribute_keys
        if wrong.any?
          raise InvalidKeyException,
                'invalid attribute keys in data assignment, must match attribute titles ' \
                "(#{'culprit'.pluralize(wrong.size)} - #{wrong.join(',')}"
        end
      end

      def initialize_structure
        pairs = metadata_attributes.map do |attribute|
          [attribute.accessor_name, nil]
        end

        update(pairs.to_h)
      end

      def pre_process_value(attribute_name, value)
        if attribute_for_attribute_name(attribute_name).nil?
          raise "Attribute with name '#{attribute_name}' not found"
        end
        attribute_for_attribute_name(attribute_name).pre_process_value(value)
      end

      def attribute_for_attribute_name(attribute_name)
        metadata_attributes.detect { |attr| attr.accessor_name == attribute_name.to_s }
      end
    end
  end
end
