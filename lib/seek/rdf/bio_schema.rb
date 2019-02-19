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

        ld = JSON.parse %(
        {
          "@context": {
                "": "http://schema.org/",
                "bio": "http://bioschemas.org/"
          },
          "@type": "#{SCHEMA_TYPES[resource.class]}",
          "@id": "#{resource.rdf_resource}",
          "name": "#{resource.title}"
        }
        )

        JSON.pretty_generate(ld)
      end

      def supported?
        BioSchema.supported?(resource)
      end
    end
  end
end
