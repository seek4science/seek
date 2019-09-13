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
        json.merge!(attributes_json)

        JSON.pretty_generate(json)
      end

      # whether the resource BioSchema was initialized with is supported
      def supported?
        BioSchema.supported?(resource)
      end

      # test directly (without initializing) whether a resource is supported
      def self.supported?(resource)
        SUPPORTED_TYPES.include?(resource.class)
      end

      private

      SUPPORTED_TYPES = [Person, Project, Event, DataFile, Organism,
                         Seek::BioSchema::DataCatalogueMockModel, Sample,
                         Document, Presentation].freeze

      def resource_decorator
        @decorator ||= ResourceDecorators::Factory.instance.get(resource)
      end

      def attributes_json
        result = {}
        resource_decorator.attributes.each do |attr|
          if (value = attr.invoke(resource_decorator))
            result[attr.property.to_s] = value
          end
        end
        result
      end
    end
  end
end
