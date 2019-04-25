module Seek
  module Stats
    class ProjectDashboardStats < DashboardStats
      attr_reader :project

      def initialize(project)
        @project = project
      end

      private

      def cache_key_base
        "Project_#{project.id}_dashboard_stats"
      end

      def scoped_activities
        @activities ||= ActivityLog.where(referenced_id: project.id, referenced_type: 'Project')
      end

      def scoped_resources
        @resources ||= scoped_isa + scoped_assets
      end

      def scoped_assets
        @assets ||= (project.assets + project.samples)
      end

      def scoped_isa
        @isa ||= project.investigations + project.studies + project.assays
      end

      def project_scope
        @project
      end
    end
  end
end
