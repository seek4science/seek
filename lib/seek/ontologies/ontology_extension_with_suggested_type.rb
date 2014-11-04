module Seek
  module Ontologies
    module OntologyExtensionWithSuggestedType
      # To enable adding suggested assay types or technology types by: include Seek::SuggestedType
      # OntologyClass is extended
      # OntologyClass#children is overridden to include children suggested

      Seek::Ontologies::OntologyClass.class_eval do
        def children_with_suggested_types
          children_without_suggested_types + suggested_children
        end

        alias_method_chain :children, :suggested_types

        def suggested_children
          case term_type
            when 'assay', 'modelling_analysis'
              SuggestedAssayType.where(parent_uri: uri.try(:to_s)).all
            when 'technology'
              SuggestedTechnologyType.where(parent_uri: uri.try(:to_s)).all
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
          case term_type
            when 'assay', 'modelling_analysis'
              Assay.find_all_by_assay_type_uri(uri.try(:to_s))
            when 'technology'
              Assay.find_all_by_technology_type_uri(uri.try(:to_s))
            else
              []
          end
        end

      end
    end
  end
end
