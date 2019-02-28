module Seek
  module BioSchema
    # Handles a CSV row from the bioschema mapping definitions
    # A row contains - type, method, property
    # Provides the ability to validate the row, check if it matches a given resource,
    # and invoke the method to get the property value
    class CSVMappingInfo
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
        resource.try(method)
      end

      def valid?
        complete? && !header?
      end
    end
  end
end
