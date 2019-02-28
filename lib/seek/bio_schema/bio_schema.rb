module Seek
  module BioSchema
    # Main entry point for generating Schema.org JSON-LD for a given resource.
    #
    # Example: Seek::BioSchema::BioSchema.new(Person.find(id)).json_ld
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
        json['@context'] = resource_decorator.context
        json['@type'] = resource_decorator.schema_type
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

      SUPPORTED_TYPES = [Person, Project].freeze

      def resource_decorator
        @decorator ||= ResourceDecorators::Factory.instance.get(resource)
      end

      def attributes_from_csv_mappings
        result = {}
        CSVReader.instance.each_row do |row|
          next unless row.matches?(resource)
          if (value = row.invoke(resource_decorator))
            result[row.property.strip] = value
          end
        end
        result
      end

      def process_mapping(method)
        resource.try(method)
      end
    end
  end
end
