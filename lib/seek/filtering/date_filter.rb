module Seek
  module Filtering
    class DateFilter
      attr_reader :field, :presets

      def initialize(field: nil, presets: [])
        @field = field
        @presets = presets
      end

      def apply(collection, values)
        values = values.map do |value|
          value = parse_value(value)
          date_range(value) if value
        end.compact

        if values.any?
          query(collection, values)
        else
          collection
        end
      end

      def options(collection, active_values)
        other_options = active_values.dup
        opts = []

        # Add each preset option, and calculate counts.
        presets.each do |value|
          date_like = value
          string_value = string_value(date_like)
          date_range = date_range(date_like)
          count = query(collection, date_range).count
          next if count.zero?
          is_active = false
          if active_values.include?(string_value)
            other_options.delete(string_value) # Prevent option appearing twice
            is_active = true
          end
          opts << Seek::Filtering::Option.new(label(date_like), string_value, count, is_active, preset: true, date_range: date_range)
        end

        # Try and parse any custom, user-supplied active filter values so they appear in the active filters section.
        other_options.each do |value|
          date_like = parse_value(value)
          next unless date_like
          opts << Seek::Filtering::Option.new(label(date_like), value, nil, true, preset: false, date_range: date_range(date_like))
        end

        opts
      end

      private

      def query(collection, date_ranges)
        collection.where("#{collection.table_name}.#{field}" => date_ranges)
      end

      # Produces a Date Range which can be supplied to `where(field: ...)` to query between the two dates.
      # If the end of the range is Float::INFINITY, it will not add a maximum date to the query.
      #
      # The string can be:
      # * an ISO8601 duration e.g. P1W for 1 week
      # * a single ISO8601 date e.g. 2016-06-02
      # * an ISO8601 date range e.g. 2016-06-02--2019-01-01
      def date_range(date_like)
        case date_like
        when ActiveSupport::Duration
          date_like.ago..Date::Infinity.new
        when Range
          date_like
        else
          date_like..Date::Infinity.new
        end
      end

      def label(object)
        case object
        when ActiveSupport::Duration
          "in the last #{object.inspect}"
        when Date
          "since #{object.iso8601}"
        when Range
          "between #{object.begin} and #{object.end}"
        else
          object.to_s
        end
      end

      def string_value(object)
        case object
        when ActiveSupport::Duration, Date
          object.iso8601
        when Range
          "#{object.begin.iso8601}/#{object.end.iso8601}"
        else
          object.to_s
        end
      end

      def parse_value(value)
        begin
          if value.start_with?('P')
            ActiveSupport::Duration.parse(value)
          elsif value.include?('/')
            dates = value.split('/').map { |d| Date.parse(d) }
            dates[0]..dates[1]
          else
            Date.parse(value)
          end
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
