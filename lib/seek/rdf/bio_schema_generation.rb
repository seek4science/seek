module Seek
  module Rdf
    module BioSchemaGeneration

      def schema_org_supported?
        BioSchema.supported?(self)
      end

      def to_schema_ld
        BioSchema.new(self).json_ld
      end

    end
  end
end