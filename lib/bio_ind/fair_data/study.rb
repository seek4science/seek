module BioInd
  module FairData
    class Study < Base

      alias_method :observation_units, :children

      def child_class
        BioInd::FairData::ObservationUnit
      end

    end
  end
end