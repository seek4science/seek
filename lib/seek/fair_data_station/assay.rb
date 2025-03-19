module Seek
  module FairDataStation
    class Assay < Base
      def title
        "Assay - #{identifier}"
      end

      def rdf_type_uri
        'http://jermontology.org/ontology/JERMOntology#Assay'
      end
    end
  end
end
