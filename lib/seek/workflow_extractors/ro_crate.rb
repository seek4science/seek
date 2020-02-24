require 'rest-client'
require 'redcarpet'
require 'redcarpet/render_strip'

module Seek
  module WorkflowExtractors
    class ROCrate < Base
      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', jpg: 'image/jpeg', default: :svg)

      def initialize(io, inner_extractor_class: nil)
        @io = io
        @inner_extractor_class = inner_extractor_class
      end

      def diagram(format = default_digram_format)
        if crate.main_workflow_diagram
          crate.main_workflow_diagram&.source&.source&.read
        end
      end

      def metadata
        # Use CWL description
        if crate.main_workflow_cwl
          m = Seek::WorkflowExtractors::CWL.new(crate.main_workflow_cwl&.source&.source).metadata
        else
          # Or try and parse main workflow
          wf = crate&.main_workflow&.source&.source
          m = case crate&.main_workflow&.programming_language&.id
              when '#cwl'
                Seek::WorkflowExtractors::CWL.new(wf).metadata
              when '#knime'
                Seek::WorkflowExtractors::KNIME.new(wf).metadata
              when '#nextflow'
                Seek::WorkflowExtractors::Nextflow.new(wf).metadata
              when '#galaxy'
                Seek::WorkflowExtractors::Galaxy.new(wf).metadata
              else
                if @inner_extractor_class
                  @inner_extractor_class.new(wf).metadata
                else
                  super
                end
              end
        end

        if crate.readme && m[:description].blank?
          markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
          m[:description] ||= markdown.render(crate.readme&.source&.source&.read)
        end

        m
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
