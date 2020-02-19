require 'rest-client'

module Seek
  module WorkflowExtractors
    class ROCrate < Base
      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', jpg: 'image/jpeg', default: :svg)

      def diagram(format = default_digram_format)
        if crate&.main_workflow&.diagram
          crate&.main_workflow&.diagram&.source&.source&.read
        end
      end

      def metadata
        # Use CWL description
        if crate&.main_workflow&.cwl_description
          return Seek::WorkflowExtractors::CWL.new(crate&.main_workflow&.cwl_description&.source&.source).metadata
        end

        # Or try and parse main workflow
        wf = crate&.main_workflow&.diagram&.source&.source
        case crate&.main_workflow&.programming_language&.id
        when '#cwl'
          return Seek::WorkflowExtractors::CWL.new(wf).metadata
        when '#knime'
          return Seek::WorkflowExtractors::KNIME.new(wf).metadata
        when '#nextflow'
          return Seek::WorkflowExtractors::Nextflow.new(wf).metadata
        when '#galaxy'
          return Seek::WorkflowExtractors::Galaxy.new(wf).metadata
        else
          return super
        end
      end

      def crate
        @crate ||= ::ROCrate::WorkflowCrateReader.read_zip(@io)
      end

      def default_diagram_format
        if crate&.main_workflow&.diagram
          ext = crate&.main_workflow&.diagram.id.split('.').last
          return ext if self.class.diagram_formats.key?(ext)
        end

        super
      end
    end
  end
end
