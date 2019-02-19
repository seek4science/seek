module Seek
  module Rdf

    class BioSchema

      class UnsupportedTypeException < RuntimeError; end

      attr_accessor :resource

      SCHEMA_TYPES = {
        Person => 'Person'
      }.freeze

      def initialize(resource)
        @resource = resource
      end

      def self.supported?(resource)
        SCHEMA_TYPES.keys.include?(resource.class)
      end

      def json_ld
        unless supported?
          raise UnsupportedTypeException.new("Bioschema not supported for #{resource.class.name}")
        end
        json = {}
        json['@context']={'':'http://schema.org','bio':'http://bioschemas.org'}
        json['@type'] = SCHEMA_TYPES[resource.class]
        json['@id'] = resource.rdf_resource
        json['name'] = resource.title

        JSON.pretty_generate(json)
      end

      def supported?
        BioSchema.supported?(resource)
      end
    end
  end
end
