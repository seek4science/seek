require 'rest-client'
require 'ro_crate'
require 'licensee'

module Seek
  module WorkflowExtractors
    # Abstract extractor class for a "Research Object-like" structured bundle of files,
    # e.g. an RO-Crate or an annotated Git repository.
    class ROLike < Base
      def initialize(obj, main_workflow_class: nil)
        @obj = obj
        @main_workflow_class = main_workflow_class
      end

      def can_render_diagram?
        diagram_path.present? || main_workflow_extractor&.can_render_diagram? || abstract_cwl_extractor&.can_render_diagram?
      end

      def diagram_extension
        path = diagram_path
        return path.split('.').last if path

        super
      end

      def generate_diagram
        if diagram_path.present? && file_exists?(diagram_path)
          file(diagram_path).read
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
        m = if abstract_cwl_extractor
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

        if file_exists?('README.md')
          m[:description] ||= file('README.md').read.force_encoding('utf-8').gsub(/^(---\s*\n.*?\n?)^(---\s*$\n?)/m,'') # Remove "Front matter"
        end

        m[:workflow_class_id] ||= main_workflow_class&.id

        m.reverse_merge!(cff_extractor.metadata) if cff_extractor
        license = extract_license(licensee_project)
        m.reverse_merge!(license: license) if license

        m
      end

      private

      def main_workflow_path
        nil
      end

      def abstract_cwl_path
        nil
      end

      def diagram_path
        nil
      end

      def licensee_project
        raise NotImplementedError
      end

      def file_exists?(path)
        raise NotImplementedError
      end

      def file(path)
        raise NotImplementedError
      end

      def main_workflow_class
        @main_workflow_class
      end

      def main_workflow_extractor
        return @main_workflow_extractor if defined?(@main_workflow_extractor)

        workflow_class = main_workflow_class
        extractor_class = workflow_class&.extractor_class || Seek::WorkflowExtractors::Base
        @main_workflow_extractor = main_workflow_path ? extractor_class.new(file(main_workflow_path)) : nil
      end

      def abstract_cwl_extractor
        return @abstract_cwl_extractor if defined?(@abstract_cwl_extractor)

        @abstract_cwl_extractor = abstract_cwl_path ? Seek::WorkflowExtractors::CWL.new(file(abstract_cwl_path)) : nil
      end

      def cff_extractor
        return @cff_extractor if defined?(@cff_extractor)

        cff = file(Seek::WorkflowExtractors::CFF::FILENAME)

        @cff_extractor = cff ? Seek::WorkflowExtractors::CFF.new(cff) : nil
      end
    end
  end
end
