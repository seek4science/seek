module Seek
  module FairDataStation
    class Investigation < Base
      alias studies children

      def child_class
        Seek::FairDataStation::Study
      end
    end
  end
end
