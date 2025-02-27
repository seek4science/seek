module Seek
  module FairDataStation
    class ObservationUnit < Base
      alias samples children

      def child_class
        Seek::FairDataStation::Sample
      end

      def rdf_type_uri
        'http://purl.org/ppeo/PPEO.owl#observation_unit'
      end
    end
  end
end
