module Seek
  module Templates
    module Extract
      # Set based construct for collecting together extraction warnings
      class Warnings
        delegate :<<, :each, :count, :merge, :empty?, :any?, to: :@warnings

        def initialize
          @warnings = Set.new
        end

        def add(text, value)
          self << Warning.new(text, value)
        end

        # A Warning, that contains the item warned about and some text describing the problem
        class Warning
          attr_reader :text, :value

          def initialize(text, value)
            @text = text
            @value = value
          end

          def ==(other)
            other.text == text && other.value == value
          end

          def eql?(other)
            other.instance_of?(self.class) && self == other
          end

          def hash
            text.hash ^ value.hash
          end
        end
      end
    end
  end
end
