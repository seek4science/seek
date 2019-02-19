module Seek
  module Rdf
    class BioSchema
      class UnsupportedTypeException < RuntimeError; end

      class CSVRow
        attr_reader :type, :method, :property
        def initialize(row)
          @type = row[0]
          @method = row[1]
          @property = row[2]
        end

        def complete?
          type && method && property
        end

        def matches?(resource)
          type == '*' || resource.class.name == type.strip
        end

        def header?
          type.casecmp('class').zero?
        end
      end

      MAPPINGS_FILE = File.join(File.dirname(__FILE__), 'bioschema_mappings.csv').freeze

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
        mappings_csv.each_with_object({}) do |row, hash|
          row = CSVRow.new(row)
          next if row.header?

          if row.complete? && row.matches?(resource)
            value = process_mapping(row.method.strip)
            hash[row.property.strip] = value if value
          end
        end
      end

      def process_mapping(method)
        resource.send(method) if resource.respond_to?(method)
      end

      def mappings_csv
        @@csv ||= CSV.read(MAPPINGS_FILE)
      end
    end
  end
end
