module Seek
  module BioSchema
    # The mixin for an ActiveRecord model to provide the ability to get the Schema.org (Bioschema.org) JSON-LD
    module Generation
      def to_schema_ld
        BioSchema.new(self).json_ld
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  def schema_org_supported?
    Seek::BioSchema::BioSchema.supported?(self)
  end
end
