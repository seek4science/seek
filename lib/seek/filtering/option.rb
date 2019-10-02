module Seek
  module Filtering
    class Option
      attr_accessor :label, :value, :count, :active

      def initialize(label, value, count, active = false)
        @label = label
        @value = value
        @count = count
        @active = active
      end

      def active?
        active
      end

      def <=>(other)
        if active?
          if other.active?
            other.count <=> count
          else
            -1
          end
        else
          if other.active?
            1
          else
            other.count <=> count
          end
        end
      end
    end
  end
end
