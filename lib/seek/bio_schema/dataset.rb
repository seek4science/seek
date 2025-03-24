module Seek
  module BioSchema
    class Dataset
      include Seek::BioSchema::Support

      delegate_missing_to :@model
      attr_reader :model

      def initialize(model)
        @model = model
      end

      def title
        model_name.human.pluralize
      end

      def description
        "#{title} in #{Seek::Config.instance_name}."
      end

      def license
        Seek::Config.metadata_license
      end

      def schema_org_supported?
        true
      end

      def is_a_version?
        false
      end
    end
  end
end
