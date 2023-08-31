module Seek
  module BioSchema
    # Main entry point for generating Schema.org JSON-LD for a given resource.
    #
    # Example: Seek::BioSchema::Serializer.new(Person.find(id)).json_ld
    class Serializer
      include ActionView::Helpers::SanitizeHelper
      attr_reader :resource

      SCHEMA_ORG = 'https://schema.org'

      # initialise with a resource
      def initialize(resource)
        @resource = resource
      end

      def json_representation
        repr = {
          '@context' => resource_decorator.context,
          '@type' => resource_decorator.schema_type
        }
        repr['dct:conformsTo'] = resource_decorator.conformance if resource_decorator.respond_to? 'conformance'
        repr = repr.merge(attributes_json)
        repr.deep_stringify_keys
      end

      # returns the JSON-LD as a String, for the resource
      def json_ld
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
                         Seek::BioSchema::DataCatalogMockModel,
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
