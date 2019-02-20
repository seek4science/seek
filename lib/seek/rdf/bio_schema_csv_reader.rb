module Seek
  module Rdf
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

      def invoke(resource)
        resource.send(method) if resource.respond_to?(method)
      end

      def valid?
        complete? && !header?
      end
    end

    class BioSchemaCSVReader
      include Singleton

      MAPPINGS_FILE = File.join(File.dirname(__FILE__), 'bioschema_mappings.csv').freeze

      def each_row
        mappings_csv.each do |row|
          csv_row = CSVRow.new(row)
          yield(csv_row) if csv_row.valid?
        end
      end

      private

      def mappings_csv
        @csv ||= CSV.read(MAPPINGS_FILE)
      end
    end
  end
end
