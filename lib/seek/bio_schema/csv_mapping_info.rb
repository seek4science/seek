module Seek
  module BioSchema
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
        resource.send(method) if resource.respond_to?(method)
      end

      def valid?
        complete? && !header?
      end
    end
  end
end
