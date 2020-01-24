module Seek
  module Filtering
    class Filter
      attr_reader :value_field, :value_mapping, :label_field, :label_mapping, :joins, :includes

      def initialize(value_field: nil, value_mapping: nil, label_field: nil, label_mapping: nil, joins: nil, includes: nil)
        @value_field = value_field
        @value_mapping = value_mapping # This is applied to given values before trying to filter
        @label_field = label_field
        @label_mapping = label_mapping # This is used to map values onto labels, usually in the case that `label_field` is undefined.
        @joins = joins
        @includes = includes
      end

      def apply(collection, values)
        values = value_mapping.call(values) if value_mapping
        collection = apply_joins(collection)
        collection.where(value_field => values).distinct
      end

      def options(collection, active_values)
        count_exp = collection.arel_table[:id].count(true) # This produces something like "COUNT(DISTINCT people.id)"
        select_fields = [value_field, count_exp, label_field].compact
        group_fields = [value_field, label_field].compact
        collection = collection.select(*select_fields)
        collection = apply_joins(collection)
        results = collection.group(group_fields).having(count_exp.gt(0)).pluck(*select_fields)
        active_options = active_values.dup

        options = []
        if results.any?
          if label_mapping
            label_mapping.call(results.map(&:first)).each.with_index do |label, index|
              results[index][2] = label
            end
          end

          results.each do |value, count, label|
            next if value.nil?
            value = value.to_s
            active = active_options.include?(value)
            active_options.delete(value) if active
            options << Seek::Filtering::Option.new(label || value, value, count, active)
          end
        end

        # Need to add options that were selected by the user, but did not appear in the results
        # (probably due to being excluded by another filter, or if a user was trying random IDs).
        if active_options.any?
          labels = if label_mapping
                     label_mapping.call(active_options)
                   elsif label_field
                     # Remove any existing conditions that may have excluded the selected options and just query the label
                     apply_joins(collection.unscoped.select(label_field))
                         .where(value_field => active_options)
                         .pluck(label_field)
                   else
                     # use the value itself as the label
                     active_options
                   end
          # Pair up values and labels create remaining options
          active_options.zip(labels).each do |value, label|
            options << Seek::Filtering::Option.new(label, value.to_s, 0, true)
          end
        end

        options.sort # Need to sort everything so active options appear at the top, then options are ordered by count.
      end

      private

      def apply_joins(collection)
        collection = collection.joins(joins) if joins
        collection = collection.includes(includes) if includes
        collection
      end
    end
  end
end
