module Seek
  module Rdf
    module BioSchemaGeneration
      def to_schema_ld
        BioSchema.new(self).json_ld
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  def schema_org_supported?
    Seek::Rdf::BioSchema.supported?(self)
  end
end

