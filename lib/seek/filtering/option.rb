module Seek
  module Filtering
    class Option
      attr_accessor :title, :value, :count, :active

      def initialize(title, value, count, active = false)
        @title = title
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
