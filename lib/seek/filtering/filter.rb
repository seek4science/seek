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
        collection = collection.joins(joins) if joins
        collection = collection.includes(includes) if includes
        collection.where(value_field => values)
      end

      def options(collection, active_values)
        select_fields = [value_field, Arel.sql("COUNT(#{value_field})"), label_field].compact
        collection = collection.select(*select_fields)
        collection = collection.joins(joins) if joins
        collection = collection.includes(includes) if includes
        opts = collection.group(value_field).pluck(*select_fields).reject { |g| g[1].zero? } # Remove 0 count results
        if label_mapping
          label_mapping.call(opts.map(&:first)).each.with_index do |label, index|
            opts[index][2] = label
          end
        end

        opts.map do |value, count, label|
          Seek::Filtering::Option.new(label || value.to_s, value.to_s, count, active_values.include?(value.to_s))
        end.sort
      end
    end
  end
end
