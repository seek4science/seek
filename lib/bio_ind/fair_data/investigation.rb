module BioInd
  module FairData
    class Investigation < Base

      alias_method :studies, :children

      def child_class
        BioInd::FairData::Study
      end
    end
  end
end
