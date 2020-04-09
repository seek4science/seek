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
          extractor_class = self.class.determine_extractor_class(crate&.main_workflow&.programming_language)
          if extractor_class
            m = extractor_class.new(wf).metadata
            m[:workflow_class_id] = extractor_class.workflow_class&.id
          elsif @inner_extractor_class
            m = @inner_extractor_class.new(wf).metadata
          else
            m = super
          end
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
                                Seek::WorkflowExtractors::KNIME,
                                Seek::WorkflowExtractors::Nextflow,
                                Seek::WorkflowExtractors::Galaxy].map do |extractor|
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
