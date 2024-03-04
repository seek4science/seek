module BioInd
  module FairData
    class Investigation < Base
      alias studies children

      def child_class
        BioInd::FairData::Study
      end
    end
  end
end
