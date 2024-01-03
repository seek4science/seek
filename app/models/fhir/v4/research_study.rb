module Fhir
  module V4
    # Decorator for a Study to make it appear as a FHIR Study.
    class ResearchStudy
      include ActiveModel::Serialization
      delegate_missing_to :@study

      def initialize(study)
        @study = study
      end

      def id
        super.to_s
      end

      def practitioner_role
        @study.creators
      end

    end
  end
end
