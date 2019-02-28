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

      # is the row complete?
      def complete?
        type && method && property
      end

      # does the row match the given resource?
      def matches?(resource)
        type == '*' || resource.class.name == type.strip
      end

      # is this row the CSV header?
      def header?
        type.casecmp('class').zero?
      end

      # invokes the method on the resource and returns the result
      def invoke(resource)
        resource.try(method)
      end

      # is this row valid?, in that it is complete and isn't the header
      def valid?
        complete? && !header?
      end
    end
  end
end
