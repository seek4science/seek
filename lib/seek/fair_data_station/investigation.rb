module Seek
  module FairDataStation
    class Investigation < Base
      alias studies children

      def child_class
        Seek::FairDataStation::Study
      end

      def rdf_type_uri
        'http://jermontology.org/ontology/JERMOntology#Investigation'
      end
    end
  end
end
