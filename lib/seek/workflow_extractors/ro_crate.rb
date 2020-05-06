require 'rest-client'
require 'redcarpet'
require 'redcarpet/render_strip'
require 'ro_crate_ruby'

module Seek
  module WorkflowExtractors
    class ROCrate < Base
      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', jpg: 'image/jpeg', default: :svg)

      def initialize(io, inner_extractor_class: nil)
        @io = io
        @main_workflow_extractor_class = inner_extractor_class
      end

      def can_render_diagram?
        crate.main_workflow_diagram.present? || main_workflow_extractor&.can_render_diagram? || abstract_cwl_extractor&.can_render_diagram?
      end

      def diagram(format = default_digram_format)
        if crate.main_workflow_diagram
          crate.main_workflow_diagram&.source&.source&.read
        elsif main_workflow_extractor&.can_render_diagram?
          main_workflow_extractor.diagram(format)
        elsif abstract_cwl_extractor&.can_render_diagram?
          abstract_cwl_extractor.diagram(format)
        end
      end

      def main_workflow_extractor
        if @main_workflow_extractor
          @main_workflow_extractor
        else
          extractor_class = @main_workflow_extractor_class ||
              self.class.determine_extractor_class(crate&.main_workflow&.programming_language) ||
              Seek::WorkflowExtractors::Base

          extractor_class.new(crate&.main_workflow&.source&.source)
        end
      end

      def abstract_cwl_extractor
        if @abstract_cwl_extractor
          @abstract_cwl_extractor
        else
          abstract_cwl = crate&.main_workflow_cwl&.source&.source
          @abstract_cwl_extractor = abstract_cwl ? Seek::WorkflowExtractors::CWL.new(abstract_cwl) : nil
        end
      end

      def metadata
        # Use CWL description
        m = if crate.main_workflow_cwl
          Seek::WorkflowExtractors::CWL.new(crate.main_workflow_cwl&.source&.source).metadata
        else
          main_workflow_extractor.metadata.merge(workflow_class_id: main_workflow_extractor.class.workflow_class&.id)
        end

        # Metadata from crate
        if crate['keywords'] && m[:tags].blank?
          m[:tags] = crate['keywords'].is_a?(Array) ? crate['keywords'] : crate['keywords'].split(',').map(&:strip)
        end

        m[:title] = crate['name'] if crate['name'].present?
        m[:description] = crate['description'] if crate['description'].present?
        m[:license] = crate['license'] if crate['license'].present?
        if m[:other_creators].blank? && crate.author.present?
          a = crate.author
          a = a.is_a?(Array) ? a : [a]
          a = a.map do |author|
            if author.is_a?(::ROCrate::Entity)
              author.name || author.id
            else
              author
            end
          end
          m[:other_creators] = a.join(', ')
        end

        if crate.readme && m[:description].blank?
          markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
          string = crate.readme&.source&.source&.read
          string = string.gsub(/^(---\s*\n.*?\n?)^(---\s*$\n?)/m,'') # Remove "Front matter"
          m[:description] ||= markdown.render(string)
        end

        m
      end

      def crate
        @crate ||= ::ROCrate::WorkflowCrateReader.read_zip(@io.is_a?(ContentBlob) ? @io.path : @io)
      end

      def default_diagram_format
        if crate&.main_workflow&.diagram
          ext = crate&.main_workflow&.diagram.id.split('.').last
          return ext if self.class.diagram_formats.key?(ext)
        end

        super
      end

      def self.determine_extractor_class(language)
        matchable = ['identifier', 'name', 'alternateName', '@id', 'url']
        @extractor_matcher ||= [Seek::WorkflowExtractors::CWL,
                                Seek::WorkflowExtractors::Galaxy,
                                Seek::WorkflowExtractors::Nextflow,
                                Seek::WorkflowExtractors::Snakemake,
                                Seek::WorkflowExtractors::KNIME].map do |extractor|
          [extractor.ro_crate_metadata.slice(*matchable), extractor]
        end

        matchable.each do |key|
          extractor = @extractor_matcher.detect do |hash, extractor|
            !language[key].nil? && !hash[key].nil? && language[key] == hash[key]
          end

          return extractor[1] if extractor
        end

        nil
      end
    end
  end
end
