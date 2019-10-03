module Seek
  module Filtering
    class YearFilter
      attr_reader :field

      def initialize(field: nil)
        @field = field
      end

      def apply(collection, years)
        return collection if years.empty?

        t = collection.arel_table
        arel = years.inject(nil) do |arel, year|
          dt = Time.new(year.to_i)
          exp = t[field].gteq(dt.beginning_of_year).and(t[field].lteq(dt.end_of_year))
          arel ? arel.or(exp) : exp
        end

        collection.where(arel)
      end

      def options(collection, active_values)
        years = collection.pluck(field).compact.map { |d| d.year }.uniq
        apply(collection, years)
        years.map do |year|
          count = apply(collection, [year]).count
          next if count.zero?
          Seek::Filtering::Option.new(year, year, count, active_values.include?(year.to_s))
        end.compact.sort_by { |o| (o.active? ? -10000 : 0) - o.value.to_i }
      end
    end
  end
end
