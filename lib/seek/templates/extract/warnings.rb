module Seek
  module Templates
    module Extract
      # Set based construct for collecting together extraction warnings
      class Warnings
        delegate :<<, :each, :count, :merge, :empty?, :any?, :group_by, to: :@warnings

        def initialize
          @warnings = Set.new
        end

        def add(item, text, value)
          self << Warning.new(item, text, value)
        end

        # A Warning, that contains the item warned about and some text describing the problem
        class Warning
          attr_reader :item, :text, :value

          def initialize(item, text, value)
            @item = item
            @text = text
            @value = value
          end

          def ==(other)
            other.item == item && other.text == text && other.value == value
          end

          def eql?(other)
            other.instance_of?(self.class) && self == other
          end

          def hash
            item.hash ^ text.hash ^ value.hash
          end
        end
      end
    end
  end
end
