module Seek
  module Stats
    class ProgrammeDashboardStats < DashboardStats
      attr_reader :programme

      def initialize(programme)
        @programme = programme
      end

      private

      def cache_key_base
        "Programme_#{programme.id}_dashboard_stats"
      end

      def scoped_activities
        @activities ||= ActivityLog.where(referenced_id: programme.project_ids, referenced_type: 'Project')
      end

      def scoped_resources
        @resources ||= (@programme.projects + scoped_isa + scoped_assets)
      end

      def scoped_assets
        @assets ||= (programme.assets + programme.samples)
      end

      def scoped_isa
        @isa ||= programme.investigations + programme.studies + programme.assays
      end

      def project_scope
        @programme.projects
      end
    end
  end
end
