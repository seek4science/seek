module Seek
  module BioSchema
    class Dataset
      include Seek::BioSchema::Support

      CONTENT_LICENSE = 'CC-BY-4.0' # TODO: This needs to be configurable per-instance!

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

      # Bioschemas compatibility
      def license
        CONTENT_LICENSE
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
