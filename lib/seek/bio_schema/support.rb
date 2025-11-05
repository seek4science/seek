module Seek
  module BioSchema
    # The mixin for an ActiveRecord model to provide the ability to get the Schema.org (Bioschema.org) JSON-LD
    module Support
      extend ActiveSupport::Concern
      # returns the JSON-LD as a String
      def to_schema_ld
        Seek::BioSchema::Serializer.new(self).json_ld
      end

      # returns the JSON-LD formatted as a pretty String for easier reading
      def to_pretty_schema_ld
        Seek::BioSchema::Serializer.new(self).pretty_json_ld
      end

      def schema_ld_statements
        RDF::Reader.for(:jsonld).new(to_schema_ld).statements
      end

      class_methods do
        def public_schema_ld_dump
          Seek::BioSchema::DataDump.new(self)
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  def schema_org_supported?
    Seek::BioSchema::Serializer.supported?(self)
  end

  def self.schema_org_supported?
    Seek::BioSchema::Serializer.supported_type?(self)
  end
end
