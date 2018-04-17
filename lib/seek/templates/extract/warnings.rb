module Seek
  module Templates
    module Extract
      # Set based construct for collecting together extraction warnings
      class Warnings
        delegate :<<, :each, :count, :merge, :empty?, :any?, to: :@warnings

        NO_PERMISSION = 1
        NOT_A_PROJECT_MEMBER = 2
        NOT_IN_DB = 3
        ID_NOT_A_VALID_URI = 4
        ID_NOT_MATCH_HOST = 5
        NO_STUDY = 6
        DUPLICATE_ASSAY = 7

        def initialize
          @warnings = Set.new
        end

        def add(problem, value, extra_info = nil)
          self << Warning.new(problem, value, extra_info)
        end

        # A Warning, that contains the type of problem, the value, and any extra info that helps construct a useful message
        class Warning
          attr_reader :problem, :value

          # extra information that can help provide the text
          attr_reader :extra_info

          def initialize(problem, value, extra_info)
            @value = value
            @problem = problem
            @extra_info = extra_info
          end

          def ==(other)
            other.problem == problem && other.value == value && other.extra_info == extra_info
          end

          def eql?(other)
            other.instance_of?(self.class) && self == other
          end

          def hash
            problem.hash ^ value.hash ^ extra_info.hash
          end
        end
      end
    end
  end
end
