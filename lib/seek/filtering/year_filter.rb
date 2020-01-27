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
        active_options = active_values.dup
        options = []
        years.each do |year|
          count = apply(collection, [year]).count
          next if count.zero?
          active = active_options.include?(year.to_s)
          active_options.delete(year.to_s) if active
          options << Seek::Filtering::Option.new(year, year, count, active)
        end

        # Add any options that were selected by the user but did not appear in the results.
        active_options.each do |year|
          options << Seek::Filtering::Option.new(year, year, 0, true)
        end

        options.compact.sort_by { |o| (o.active? ? -10000 : 0) - o.value.to_i } # Sort by year, descending
      end
    end
  end
end
