module Seek
  module Rdf
    class BioSchema
      class UnsupportedTypeException < RuntimeError; end

      attr_accessor :resource

      SCHEMA_TYPES = {
        Person => 'Person'
      }.freeze

      def initialize(resource)
        @resource = resource
      end

      def self.supported?(resource)
        SCHEMA_TYPES.keys.include?(resource.class)
      end

      def json_ld
        unless supported?
          raise UnsupportedTypeException, "Bioschema not supported for #{resource.class.name}"
        end
        json = {}
        json['@context'] = { '': 'http://schema.org', 'bio': 'http://bioschemas.org' }
        json['@type'] = SCHEMA_TYPES[resource.class]
        json.merge!(attributes_from_csv_mappings)

        JSON.pretty_generate(json)
      end

      def supported?
        BioSchema.supported?(resource)
      end

      private

      def attributes_from_csv_mappings
        result = {}
        BioSchemaCSVReader.instance.each_row do |row|
          next unless row.matches?(resource)
          if value = row.invoke(resource)
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
