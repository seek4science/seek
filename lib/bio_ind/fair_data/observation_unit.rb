module BioInd
  module FairData
    class ObservationUnit < Base
      alias samples children

      def child_class
        BioInd::FairData::Sample
      end
    end
  end
end
