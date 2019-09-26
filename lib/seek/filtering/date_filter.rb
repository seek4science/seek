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

      def options(collection, active_values)
        @date_ranges.map do |max_age|
          count = apply(collection, max_age.ago).count
          next if count.zero?
          Seek::Filtering::Option.new("in the last #{max_age.inspect}", max_age.to_i.to_s, count, active_values.include?(max_age.to_s))
        end.compact
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
