require 'rdf'

module Seek
  module Ontologies

    class TechnologyTypeReader < OntologyReader

      TERM_TYPE="technology"

      def default_parent_class_uri
        RDF::URI.new(Seek::Config.technology_type_base_uri)
      end

      def ontology_file
        Seek::Config.technology_type_ontology_file
      end

      def ontology_term_type
        TERM_TYPE
      end
    end
  end
end