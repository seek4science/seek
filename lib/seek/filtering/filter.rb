module Seek
  module Filtering
    class Filter
      attr_reader :value_field, :label_field, :label_mapping, :joins, :includes

      def initialize(value_field: nil, label_field: nil, label_mapping: nil, joins: nil, includes: nil)
        @value_field = value_field
        @label_field = label_field
        @label_mapping = label_mapping
        @joins = joins
        @includes = includes
      end

      def apply(collection, values)
        collection = collection.joins(joins) if joins
        collection = collection.includes(includes) if includes
        collection.where(value_field => values)
      end

      def options(collection, active_values)
        select_fields = [value_field, "COUNT(#{value_field})", label_field].compact.map { |f| Arel.sql(f) }
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
