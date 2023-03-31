require 'rest-client'
require 'ro_crate'

module Seek
  module WorkflowExtractors
    class GitRepo < Base
      def initialize(git_version, main_workflow_class: nil)
        @git_version = git_version
        @main_workflow_class = main_workflow_class
      end

      def can_render_diagram?
        @git_version.path_for_key(:diagram).present? || main_workflow_extractor&.can_render_diagram? || abstract_cwl_extractor&.can_render_diagram?
      end

      def diagram_extension
        path = @git_version.path_for_key(:diagram)
        return path.split('.').last if path

        super
      end

      def generate_diagram
        if @git_version.path_for_key(:diagram).present?
          @git_version.file_contents(@git_version.path_for_key(:diagram))
        elsif main_workflow_extractor&.can_render_diagram?
          main_workflow_extractor.generate_diagram
        elsif abstract_cwl_extractor&.can_render_diagram?
          abstract_cwl_extractor.generate_diagram
        else
          nil
        end
      end

      def metadata
        # Use CWL description
        m = if @git_version.path_for_key(:abstract_cwl).present?
              begin
                abstract_cwl_extractor.metadata
              rescue StandardError => e
                Rails.logger.error('Error extracting abstract CWL:')
                Rails.logger.error(e)
                { errors: ["Couldn't parse abstract CWL"] }
              end
            else
              begin
                main_workflow_extractor.metadata
              rescue StandardError => e
                Rails.logger.error('Error extracting workflow:')
                Rails.logger.error(e)
                { errors: ["Couldn't parse main workflow"] }
              end
            end

        if @git_version.file_exists?('README.md')
          m[:description] ||= @git_version.file_contents('README.md').force_encoding('utf-8')
        end

        m.reverse_merge!(cff_extractor.metadata) if cff_extractor

        m[:source_link_url] ||= @git_version.git_repository&.remote

        m
      end

      private

      def main_workflow_extractor
        return @main_workflow_extractor if defined?(@main_workflow_extractor)

        workflow_class = @main_workflow_class
        extractor_class = workflow_class&.extractor_class || Seek::WorkflowExtractors::Base
        main_workflow_path = @git_version.path_for_key(:main_workflow)
        @main_workflow_extractor = main_workflow_path ? extractor_class.new(@git_version.file_contents(main_workflow_path, fetch_remote: true)) : nil
      end

      def abstract_cwl_extractor
        return @abstract_cwl_extractor if defined?(@abstract_cwl_extractor)

        abstract_cwl_path = @git_version.path_for_key(:abstract_cwl)
        @abstract_cwl_extractor = abstract_cwl_path ? Seek::WorkflowExtractors::CWL.new(@git_version.file_contents(abstract_cwl_path, fetch_remote: true)) : nil
      end

      def cff_extractor
        return @cff_extractor if defined?(@cff_extractor)

        cff = @git_version.get_blob(Seek::WorkflowExtractors::CFF::FILENAME)

        @cff_extractor = cff ? Seek::WorkflowExtractors::CFF.new(cff) : nil
      end
    end
  end
end
