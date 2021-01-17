module Seek
  module Stats
    class DashboardStats
      def asset_activity(action, start_date, end_date, type: nil)
        resource_types = type || Seek::Util.asset_types.map(&:name)
        Rails.cache.fetch("#{cache_key_base}_#{type || 'all'}_activity_#{action}_#{start_date}_#{end_date}", expires_in: 12.hours) do
          scoped_activities
            .where(action: action)
            .where('created_at > ? AND created_at < ?', start_date, end_date)
            .where(activity_loggable_type: resource_types)
            .group(:activity_loggable_type, :activity_loggable_id).count.to_a
            .map { |(type, id), count| [type.constantize.find_by_id(id), count] }
            .select { |resource, _| !resource.nil? && resource.can_view? }
            .sort_by { |x| -x[1] }.first(10)
        end
      end

      def contributor_activity(start_date, end_date)
        Rails.cache.fetch("#{cache_key_base}_contributor_activity_#{start_date}_#{end_date}", expires_in: 12.hours) do
          scoped_activities
            .where(action: %w[update create])
            .where('created_at > ? AND created_at < ?', start_date, end_date)
            .group(:culprit_type, :culprit_id).count.to_a
            .map { |(type, id), count| [type.constantize.find_by_id(id).try(:person), count] }
            .reject { |resource, _| resource.nil? }
            .sort_by { |x| -x[1] }
            .first(10)
        end
      end

      def contributions(start_date, end_date, interval)
        Rails.cache.fetch("#{cache_key_base}_contributions_#{interval}_#{start_date}_#{end_date}", expires_in: 12.hours) do
          strft = case interval
                  when 'year'
                    '%Y'
                  when 'month'
                    '%B %Y'
                  when 'day'
                    '%Y-%m-%d'
                  end

          assets = scoped_resources
          assets.select! { |a| a.created_at >= start_date && a.created_at <= end_date }
          date_grouped = assets.group_by { |a| a.created_at.strftime(strft) }
          types = assets.map(&:class).uniq
          dates = dates_between(start_date, end_date, interval)

          labels = dates.map { |d| d.strftime(strft) }
          datasets = {}
          types.each do |type|
            datasets[type] = dates.map do |date|
              assets_for_date = date_grouped[date.strftime(strft)]
              assets_for_date ? assets_for_date.select { |a| a.class == type }.count : 0
            end
          end
          { labels: labels, datasets: datasets }
        end
      end

      def asset_accessibility(start_date, end_date, type: nil)
        Rails.cache.fetch("#{cache_key_base}_#{type || 'all'}_asset_accessibility_#{start_date}_#{end_date}", expires_in: 3.hours) do
          assets = scoped_isa + scoped_assets
          assets.select! {|a| a.class.name == type} if type
          assets.select! {|a| a.created_at >= start_date && a.created_at <= end_date}
          published_count = assets.count(&:is_published?)

          project_accessible_count = assets.count do |asset|
            !asset.is_published? && asset.projects_accessible?(project_scope || asset.projects)
          end
          others_count = assets.count - published_count - project_accessible_count
          {published: published_count, project_accessible: project_accessible_count, other: others_count}
        end
      end

      def clear_caches
        Rails.cache.delete_matched(/#{cache_key_base}/)
      end

      private

      def cache_key_base
        'admin_dashboard_stats'
      end

      def scoped_activities
        @activities ||= ActivityLog
      end

      def scoped_resources
        @resources ||= (Programme.all + Project.all + scoped_isa + scoped_assets)
      end

      def scoped_assets
        @assets ||= Seek::Util.asset_types.map(&:all).flatten
      end

      def scoped_isa
        @isa ||= Investigation.all + Study.all + Assay.all
      end

      def project_scope
        nil
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
