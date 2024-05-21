module Seek
  module FairDataStation
    class ObservationUnit < Base
      alias samples children

      def child_class
        Seek::FairDataStation::Sample
      end
    end
  end
end
