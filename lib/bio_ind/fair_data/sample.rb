module BioInd
  module FairData
    class Sample < Base
      alias assays children

      def child_class
        BioInd::FairData::Assay
      end
    end
  end
end
