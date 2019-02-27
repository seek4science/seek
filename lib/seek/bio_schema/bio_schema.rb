module Seek
  module BioSchema
    class BioSchema
      attr_reader :resource

      def initialize(resource)
        @resource = resource
      end

      def json_ld
        unless supported?
          raise UnsupportedTypeException, "Bioschema not supported for #{resource.class.name}"
        end
        json = {}
        json['@context'] = resource_wrapper.context
        json['@type'] = resource_wrapper.schema_type
        json.merge!(attributes_from_csv_mappings)

        JSON.pretty_generate(json)
      end

      def supported?
        BioSchema.supported?(resource)
      end

      def self.supported?(resource)
        SUPPORTED_TYPES.include?(resource.class)
      end

      private

      SUPPORTED_TYPES = [Person].freeze

      def resource_wrapper
        ResourceWrappers::Factory.instance.get(resource)
      end

      def attributes_from_csv_mappings
        result = {}
        CSVReader.instance.each_row do |row|
          next unless row.matches?(resource)
          if (value = row.invoke(resource_wrapper))
            result[row.property.strip] = value
          end
        end
        result
      end

      def process_mapping(method)
        resource.send(method) if resource.respond_to?(method)
      end
    end
  end
end
