require 'rdf'

module Seek
  module Ontologies
    class SourceTypeReader < OntologyReader

      def default_parent_class_uri
        # RDF::URI.new(Seek::Config.source_type_base_uri)
        RDF::URI.new("http://purl.obolibrary.org/obo/BFO_0000015")
      end

      def ontology_file
        # Seek::Config.source_type_ontology_file
        "EFO.rdf"
      end

      def ontology_term_type
        nil
      end
    end
  end
end
