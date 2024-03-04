module BioInd
  module FairData
    class Sample < Base

      alias_method :assays, :children

      def child_class
        BioInd::FairData::Assay
      end

    end
  end
end