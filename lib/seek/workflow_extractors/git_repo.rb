require 'rest-client'
require 'redcarpet'
require 'redcarpet/render_strip'
require 'ro_crate'

module Seek
  module WorkflowExtractors
    class GitRepo < Base
      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', jpg: 'image/jpeg', default: :svg)

      def initialize(git_version, main_workflow_class: nil)
        @git_version = git_version
        @main_workflow_class = main_workflow_class
      end

      def can_render_diagram?
        @git_version.path_for_key(:diagram).present? || main_workflow_extractor&.can_render_diagram? || abstract_cwl_extractor&.can_render_diagram?
      end

      def default_diagram_format
        diagram_path = @git_version.path_for_key(:diagram)
        if diagram_path
          ext = diagram_path.split('.').last
          return ext if self.class.diagram_formats.key?(ext)
        end

        super
      end

      def generate_diagram(format = nil)
        if @git_version.path_for_key(:diagram).present?
          @git_version.file_contents(@git_version.path_for_key(:diagram)).tap {|x| puts x}
        elsif main_workflow_extractor&.can_render_diagram?
          main_workflow_extractor.generate_diagram(format)
        elsif abstract_cwl_extractor&.can_render_diagram?
          abstract_cwl_extractor.generate_diagram(format)
        else
          nil
        end
      end

      def metadata
        # Use CWL description
        m = if @git_version.path_for_key(:abstract_cwl).present?
              abstract_cwl_extractor.metadata
            else
              main_workflow_extractor.metadata
            end

        m[:source_link_url] = @git_version.git_repository&.remote

        if @git_version.file_exists?('README.md')
          m[:description] ||= @git_version.file_contents('README.md').force_encoding('utf-8')
        end

        return m
      end

      private

      def main_workflow_extractor
        return @main_workflow_extractor if @main_workflow_extractor

        workflow_class = @main_workflow_class
        extractor_class = workflow_class&.extractor_class || Seek::WorkflowExtractors::Base
        main_workflow_path = @git_version.path_for_key(:main_workflow)
        @main_workflow_extractor = main_workflow_path ? extractor_class.new(@git_version.file_contents(main_workflow_path)) : nil
      end

      def abstract_cwl_extractor
        return @abstract_cwl_extractor if @abstract_cwl_extractor

        abstract_cwl_path = @git_version.path_for_key(:abstract_cwl)
        @abstract_cwl_extractor = abstract_cwl_path ? Seek::WorkflowExtractors::CWL.new(@git_version.file_contents(abstract_cwl_path)) : nil
      end
    end
  end
end
