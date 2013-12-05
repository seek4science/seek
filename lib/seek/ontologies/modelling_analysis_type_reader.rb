module Seek
  module Ontologies
    class ModellingAnalysisTypeReader < OntologyReader

      def default_parent_class_uri
        RDF::URI.new(Seek::Config.modelling_analysis_type_base_uri)
      end

      def ontology_file
        Seek::Config.modelling_analysis_type_ontology_file
      end
    end
  end
end