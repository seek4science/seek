module Seek
  module BioSchema
    # The mixin for an ActiveRecord model to provide the ability to get the Schema.org (Bioschema.org) JSON-LD
    module Support
      extend ActiveSupport::Concern

      def to_schema_ld
        Seek::BioSchema::Serializer.new(self).json_ld
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
