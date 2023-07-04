require 'rest-client'
require 'ro_crate'
require 'licensee'

module Seek
  module WorkflowExtractors
    class GitRepo < ROLike
      def metadata
        m = super

        m[:source_link_url] ||= @obj.git_repository&.remote

        m
      end

      private

      def main_workflow_path
        @obj.path_for_key(:main_workflow)
      end

      def abstract_cwl_path
        @obj.path_for_key(:abstract_cwl)
      end

      def diagram_path
        @obj.path_for_key(:diagram)
      end

      def file_exists?(path)
        @obj.file_exists?(path)
      end

      def file(path)
        @obj.get_blob(path)&.file(fetch_remote: true)
      end

      def licensee_project
        @licensee_project ||= ::Licensee::Projects::GitVersionProject.new(@obj)
      end
    end
  end
end
