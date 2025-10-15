# frozen_string_literal: true
module Seek
  module Filtering
    class BooleanFilter < Filter
      def options(collection, active_values = [])
        collection = apply_joins(collection) || []
        true_result = apply(collection, ['true'])
        false_result = apply(collection, ['false'])
        true_active_actions = active_values.include? 'true'
        false_active_actions = active_values.include? 'false'

        [
          Seek::Filtering::Option.new('Yes', 'true', true_result.count, true_active_actions, { replace_filters: true }),
          Seek::Filtering::Option.new('No', 'false', false_result.count, false_active_actions, { replace_filters: true })
        ]
      end
    end
  end
end
