require 'rdf'

module Seek
  module Ontologies

    class TechnologyTypeReader < OntologyReader

      def default_parent_class_uri
        RDF::URI.new(Seek::Config.technology_type_base_uri)
      end

      def ontology_file
        Seek::Config.technology_type_ontology_file
      end

    end
  end
end