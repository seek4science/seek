module Seek
  module Openbis

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
