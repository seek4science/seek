module Seek
  module BioSchema
    # Main entry point for generating Schema.org JSON-LD for a given resource.
    #
    # Example: Seek::BioSchema::BioSchema.new(Person.find(id)).json_ld
    class BioSchema
      include ActionView::Helpers::SanitizeHelper
      attr_reader :resource

      # initialise with a resource
      def initialize(resource)
        @resource = resource
      end

      # returns the JSON-LD as a String, for the resource
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

      # whether the resource BioSchema was initialized with is supported
      def supported?
        BioSchema.supported?(resource)
      end

      # test directly (without intializing) whether a resource is supported
      def self.supported?(resource)
        SUPPORTED_TYPES.include?(resource.class)
      end

      private

      SUPPORTED_TYPES = [Person, Project, Event, DataFile].freeze

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
