require 'rdf'

module Seek
  module Ontologies

    class AssayTypeReader < OntologyReader

      def default_parent_class_uri
        #TODO: this will become configurable
        RDF::URI.new("http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type")
      end

      def ontology_file
        #TODO: this will become configurable
        "JERM.rdf"
      end

    end
  end
end