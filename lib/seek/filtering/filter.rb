module Seek
  module Filtering
    class Filter
      attr_reader :field, :title_field, :title_mapping, :joins, :includes

      def initialize(field: nil, title_field: nil, title_mapping: nil, joins: nil, includes: nil)
        @field = field
        @title_field = title_field
        @title_mapping = title_mapping
        @joins = joins
        @includes = includes
        @count_field = "COUNT(#{field})"
        @select_fields = [field, @count_field, title_field].compact.map { |f| Arel.sql(f) }
      end

      def apply(collection, values)
        collection = collection.joins(joins) if joins
        collection = collection.includes(includes) if includes
        collection.where(field => values)
      end

      def options(collection, active_values)
        collection = collection.select(*@select_fields)
        collection = collection.joins(joins) if joins
        collection = collection.includes(includes) if includes
        opts = collection.group(field).pluck(*@select_fields).reject { |g| g[1].zero? } # Remove 0 count results
        if title_mapping
          title_mapping.call(opts.map(&:first)).each.with_index do |title, index|
            opts[index][2] = title
          end
        end

        opts.map do |value, count, title|
          {
              title: title || value.to_s,
              value: value.to_s,
              count: count,
              active: active_values.include?(value.to_s)
          }
        end.sort_by { |g| -g[:count] }
      end
    end
  end
end
