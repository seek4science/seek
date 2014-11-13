module Seek
  module Ontologies
    module OntologyClassExtensionWithSuggestedType
      extend ActiveSupport::Concern

      included do
        alias_method_chain :children, :suggested_types
      end

      def children_with_suggested_types
        children_without_suggested_types + suggested_children
      end

      def suggested_children
        case term_type
          when 'assay', 'modelling_analysis'
            SuggestedAssayType.where(ontology_uri: uri.try(:to_s)).all
          when 'technology'
            SuggestedTechnologyType.where(ontology_uri: uri.try(:to_s)).all
          else
            []
        end
      end

      def is_suggested_type?
        false
      end

      def can_edit?(_user = User.current_user)
        false
      end

      def can_destroy?(_user = User.current_user)
        false
      end

      def assays
        uris = hash_by_uri.keys
        case term_type
          when 'assay', 'modelling_analysis'
            Assay.where(:assay_type_uri => uris)
          when 'technology'
            Assay.where(:technology_type_uri => uris)
          else
            []
        end
      end
    end
  end
end
