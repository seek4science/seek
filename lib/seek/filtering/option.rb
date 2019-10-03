module Seek
  module Filtering
    class Option
      attr_accessor :label, :value, :count, :active

      def initialize(label, value, count, active = false)
        @label = label.to_s
        @value = value.to_s
        @count = count
        @active = active
      end

      def active?
        active
      end

      def <=>(other)
        if active?
          return -1 unless other.active?
        elsif other.active?
          return 1
        end

        other.count <=> count
      end
    end
  end
end
