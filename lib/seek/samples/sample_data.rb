module Seek
  module Samples
    class SampleData < HashWithIndifferentAccess

      attr_accessor :sample_type

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
      alias_method :orig_set_value, :[]=

      def []=(key, value)
        super(key, pre_process_value(key, value))
      end

      # Mass assign values provided as a hash. Pre-processes by default, but can be avoided by passing `pre_process: false`
      def mass_assign(hash, pre_process: true)
        method = pre_process ? :[]= : :orig_set_value
        hash.each do |key, value|
          self.send(method, key, value)
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
