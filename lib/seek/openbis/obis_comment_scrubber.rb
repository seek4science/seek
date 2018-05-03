module Seek
  module Openbis
    # Change OBIS xml comments elements into html ones for display
    class ObisCommentScrubber < Loofah::Scrubber
      def initialize
        @direction = :top_down
      end

      def scrub(node)
        case node.name
        when 'commententry' then node.name = 'p'
        when 'root' then node.name = 'div'
        end
      end
    end
  end
end
