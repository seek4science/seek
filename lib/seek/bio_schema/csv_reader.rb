module Seek
  module BioSchema
    # Reads the CSV mapping file, that contains details about the propery and method
    # to be invoked for a given resource type
    # a wildcard (*) for the type means if applies to any resource type that is supported
    class CSVReader
      include Singleton

      MAPPINGS_FILE = File.join(File.dirname(__FILE__), 'bioschema_mappings.csv').freeze

      def each_row
        mappings_csv.each do |row|
          info = CSVMappingInfo.new(row)
          yield(info) if info.valid?
        end
      end

      private

      def mappings_csv
        @csv ||= CSV.read(MAPPINGS_FILE)
      end
    end
  end
end
