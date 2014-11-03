module Seek
  module Ontologies
    class ModellingAnalysisTypeReader < OntologyReader

      TERM_TYPE="modelling_analysis"

      def default_parent_class_uri
        RDF::URI.new(Seek::Config.modelling_analysis_type_base_uri)
      end

      def ontology_file
        Seek::Config.modelling_analysis_type_ontology_file
      end

      def ontology_term_type
        TERM_TYPE
      end
    end
  end
end