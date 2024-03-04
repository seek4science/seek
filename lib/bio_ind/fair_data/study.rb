module BioInd
  module FairData
    class Study < Base
      alias observation_units children

      def assays
        observation_units.collect(&:samples).flatten.collect(&:assays).flatten.uniq
      end

      def child_class
        BioInd::FairData::ObservationUnit
      end
    end
  end
end
