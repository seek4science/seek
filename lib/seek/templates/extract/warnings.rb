module Seek
  module Templates
    module Extract
      # Set based construct for collecting together extraction warnings
      class Warnings
        delegate :<<, :each, :count, :merge, :empty?, :any?, to: :@warnings

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

          VALID_PROBLEMS = %i[no_permission not_a_project_member not_in_db id_not_a_valid_match id_not_match_host no_study duplicate_assay].freeze

          def initialize(problem, value, extra_info)
            @value = value
            @problem = problem
            @extra_info = extra_info
            check_problem

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

          private

          def check_problem
            raise("#{problem} is not a valid warning problem - valid options are: #{VALID_PROBLEMS.join(', ')}") unless VALID_PROBLEMS.include?(problem)
          end
        end
      end
    end
  end
end
