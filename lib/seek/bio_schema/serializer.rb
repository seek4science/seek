module Seek
  module BioSchema
    # Main entry point for generating Schema.org JSON-LD for a given resource.
    #
    # Example: Seek::BioSchema::Serializer.new(Person.find(id)).json_ld
    class Serializer
      include ActionView::Helpers::SanitizeHelper
      attr_reader :resource

      SCHEMA_ORG = 'https://schema.org/'.freeze
      DCT = 'http://purl.org/dc/terms/'.freeze

      # initialise with a resource
      def initialize(resource)
        @resource = resource
      end

      def json_representation
        representation = {
          '@context' => resource_decorator.context,
          '@type' => resource_decorator.schema_type
        }
        if resource_decorator.respond_to? 'conformance'
          representation['dct:conformsTo'] = { '@id' => resource_decorator.conformance }
        end
        representation = representation.merge(attributes_json)
        # After attributes_json has been generated, additional context will be populated
        representation['@context'].merge!(resource_decorator.additional_context)
        representation.deep_stringify_keys
      end

      # returns the JSON-LD as a String, for the resource
      def json_ld
        JSON.generate(json_representation)
      end

      # returns the JSON-LD as a pretty String, for the resource
      def pretty_json_ld
        JSON.pretty_generate(json_representation)
      end

      # whether the resource BioSchema was initialized with is supported
      def supported?
        Serializer.supported?(resource)
      end

      # test directly (without initializing) whether a resource is supported
      def self.supported?(resource)
        supported_types.include?(resource.class)
      end

      # Check if a class is supported
      def self.supported_type?(klass)
        supported_types.include?(klass)
      end

      def self.supported_types
        SUPPORTED_TYPES
      end

      private_class_method :supported_types

      private

      SUPPORTED_TYPES = [Person, Project, Event, DataFile, Organism, HumanDisease,
                         Seek::BioSchema::DataCatalogMockModel, Sop,
                         Document, Presentation, Workflow, Collection,
                         Institution, Programme, Sample, AssetsCreator].freeze

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
