require 'rdf'

module Seek
  module Ontologies

    class AssayTypeReader < OntologyReader

      def default_parent_class_uri
        RDF::URI.new(Seek::Config.assay_type_base_uri)
      end

      def ontology_file
        Seek::Config.assay_type_ontology_file
      end

    end
  end
end