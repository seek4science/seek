module Seek
  module BioSchema
    # The mixin for an ActiveRecord model to provide the ability to get the Schema.org (Bioschema.org) JSON-LD
    module Support
      def to_schema_ld
        Seek::BioSchema::Serializer.new(self).json_ld
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  def schema_org_supported?
    Seek::BioSchema::Serializer.supported?(self)
  end
end
