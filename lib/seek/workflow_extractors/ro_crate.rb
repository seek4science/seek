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

      def can_render_diagram?
        !crate.main_workflow_diagram.nil?
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
          extractor = self.class.extractor_from_programming_language(crate&.main_workflow&.programming_language)
          if extractor
            extractor
          elsif @inner_extractor_class
            @inner_extractor_class.new(wf).metadata
          else
            super
          end
        end

        if crate.readme && m[:description].blank?
          markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
          m[:description] ||= markdown.render(crate.readme&.source&.source&.read)
        end

        if crate['keywords'] && m[:tags].blank?
          m[:tags] = crate['keywords'].is_a?(Array) ? crate['keywords'] : crate['keywords'].split(',').map(&:strip)
        end

        m[:title] ||= crate['name']
        m[:description] ||= crate['description']
        m[:license] ||= crate['license']

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

      def self.extractor_from_programming_language(language)
        matchable = ['identifier', 'name', 'alternateName', '@id', 'url']
        @extractor_matcher ||= [Seek::WorkflowExtractors::CWL,
                                Seek::WorkflowExtractors::KNIME,
                                Seek::WorkflowExtractors::Nextflow,
                                Seek::WorkflowExtractors::Galaxy].map do |extractor|
          [extractor.ro_crate_metadata.slice(*matchable), extractor]
        end

        matchable.each do |key|
          extractor = @extractor_matcher.detect do |hash, extractor|
            extractor if (!language[key].nil? && !hash[key].nil? && language[key] == hash[key])
          end

          return extractor if extractor
        end

        nil
      end
    end
  end
end
