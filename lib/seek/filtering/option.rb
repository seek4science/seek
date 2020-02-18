module Seek
  module Filtering
    class Option
      attr_accessor :label, :value, :count, :active
      attr_reader :data

      def initialize(label, value, count, active = false, data = {})
        @label = label.to_s
        @value = value.to_s
        @count = count
        @active = active
        @data = data # Any misc data that needs to be stored for the option (e.g. for use in the view).
      end

      def active?
        active
      end

      # Bumps active filter options ahead of non-active ones, then sorts by count.
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
