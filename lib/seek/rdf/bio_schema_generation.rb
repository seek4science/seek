module Seek
  module Rdf
    module BioSchemaGeneration

      def to_schema_ld
        BioSchema.new(self).json_ld
      end

    end
  end
end