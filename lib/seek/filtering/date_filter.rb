module Seek
  module Filtering
    class DateFilter
      attr_reader :field, :date_ranges

      def initialize(field: nil, date_ranges: [])
        @field = field
        @date_ranges = date_ranges
      end

      def apply(collection, date)
        collection.where("#{collection.table_name}.#{field} > ?", coerce_date(date))
      end

      def options(collection)
        @date_ranges.map do |max_age|
          count = apply(collection, max_age.ago).count
          [max_age.to_i.to_s, count, "in the last #{max_age.inspect}"]
        end.reject { |g| g[1].zero? }
      end

      private

      def coerce_date(date)
        date = date.first if date.is_a?(Array)
        date = (Time.now - date.to_i) if date.is_a?(String) || date.is_a?(Integer)
        date
      end
    end
  end
end
