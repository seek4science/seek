module Seek
  module BioSchema
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
