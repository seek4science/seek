module Seek
  module Samples
    class SampleData < HashWithIndifferentAccess

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
      def []=(key, value)
        super(key, pre_process_value(key, value))
      end

      # Mass pre-processes values provided as a hash
      def mass_assign(hash)
        hash.each do |key, value|
          self[key] = value
        end
      end

      private

      def initialize_structure
        pairs = @sample_type.sample_attributes.map do |attribute|
          [attribute.hash_key, nil]
        end

        update(pairs.to_h)
      end

      def pre_process_value(attribute_name, value)
        attribute_for_attribute_name(attribute_name).pre_process_value(value)
      end

      def attribute_for_attribute_name(attribute_name)
        @sample_type.sample_attributes.where(accessor_name: attribute_name).first
      end

    end
  end
end