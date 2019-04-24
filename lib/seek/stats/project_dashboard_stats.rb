module Seek
  module Stats
    class ProjectDashboardStats < DashboardStats

      attr_reader :scope

      def initialize(scope)
        @scope = scope
      end

      private

      def cache_key_base
        "#{scope.class.name}_#{scope.id}_dashboard_stats"
      end

      def scoped_activities
        @activities ||= ActivityLog.where(referenced_id: scope.id, referenced_type: scope.class.name)
      end

      def scoped_resources
        @resources ||= (scoped_isa + scoped_assets)
      end

      def scoped_assets
        @assets ||= (scope.assets + scope.samples)
      end

      def scoped_isa
        @isa ||= scope.investigations + scope.studies + scope.assays
      end

      def dates_between(start_date, end_date, interval = 'month')
        case interval
        when 'year'
          transform = ->(date) { Date.parse("#{date.strftime('%Y')}-01-01") }
          increment = ->(date) { date >> 12 }
        when 'month'
          transform = ->(date) { Date.parse("#{date.strftime('%Y-%m')}-01") }
          increment = ->(date) { date >> 1 }
        when 'day'
          transform = ->(date) { date }
          increment = ->(date) { date + 1 }
        else
          raise 'Invalid interval. Valid intervals: year, month, day'
        end

        start_date = transform.call(start_date)
        end_date = transform.call(end_date)
        date = start_date
        dates = []

        while date <= end_date
          dates << date
          date = increment.call(date)
        end

        dates
      end
    end
  end
end
