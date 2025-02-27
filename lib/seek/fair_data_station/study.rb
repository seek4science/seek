module Seek
  module FairDataStation
    class Study < Base
      alias observation_units children

      def assays
        observation_units.collect(&:samples).flatten.collect(&:assays).flatten.uniq
      end

      def child_class
        Seek::FairDataStation::ObservationUnit
      end

      def rdf_type_uri
        'http://jermontology.org/ontology/JERMOntology#Study'
      end
    end
  end
end
