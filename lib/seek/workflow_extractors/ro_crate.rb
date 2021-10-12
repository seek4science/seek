require 'rest-client'
require 'ro_crate'

module Seek
  module WorkflowExtractors
    class ROCrate < Base
      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', jpg: 'image/jpeg', default: :svg)

      def initialize(io, main_workflow_class: nil)
        @io = io
        @main_workflow_class = main_workflow_class
      end

      def has_tests?
        open_crate do |crate|
          crate.test_suites.any?
        end
      end

      def can_render_diagram?
        open_crate do |crate|
          crate.main_workflow_diagram.present? || main_workflow_extractor(crate)&.can_render_diagram? || abstract_cwl_extractor(crate)&.can_render_diagram?
        end
      end

      def diagram(format = nil)
        open_crate do |crate|
          format ||= default_diagram_format

          return crate.main_workflow_diagram&.source&.read if crate.main_workflow_diagram

          extractor = main_workflow_extractor(crate)
          return extractor.diagram(format) if extractor&.can_render_diagram?

          extractor = abstract_cwl_extractor(crate)
          return extractor.diagram(format) if extractor&.can_render_diagram?

          return nil
        end
      end

      def metadata
        open_crate do |crate|
          # Use CWL description
          m = if crate.main_workflow_cwl
                abstract_cwl_extractor(crate).metadata
              else
                main_workflow_extractor(crate).metadata
              end
          m[:workflow_class_id] ||= main_workflow_class(crate)&.id

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

          source_url = crate['isBasedOn'] || crate['url'] || crate.main_workflow['url']
          if source_url
            handler = ContentBlob.remote_content_handler_for(source_url)
            if handler.respond_to?(:repository_url)
              source_url = handler.repository_url
            elsif handler.respond_to?(:display_url)
              source_url = handler.display_url
            end
            m[:source_link_url] = source_url
          end

          if crate.readme && m[:description].blank?
            string = crate.readme&.source&.read
            string = string.gsub(/^(---\s*\n.*?\n?)^(---\s*$\n?)/m,'') # Remove "Front matter"
            m[:description] ||= string
          end

          return m
        end
      end

      def open_crate
        if @opened_crate
          v = yield @opened_crate
          return v
        end

        v = Dir.mktmpdir('ro-crate') do |dir|
          @opened_crate = ::ROCrate::WorkflowCrateReader.read_zip(@io.is_a?(ContentBlob) ? @io.data_io_object : @io, target_dir: dir)
          yield @opened_crate
        end

        @opened_crate = nil

        v
      end

      def default_diagram_format
        open_crate do |crate|
          if crate&.main_workflow&.diagram
            ext = crate&.main_workflow&.diagram.id.split('.').last
            return ext if self.class.diagram_formats.key?(ext)
          end

          super
        end
      end

      private

      def main_workflow_class(crate)
        return @main_workflow_class if @main_workflow_class

        WorkflowClass.match_from_metadata(crate&.main_workflow&.programming_language&.properties || {})
      end

      def main_workflow_extractor(crate)
        workflow_class = main_workflow_class(crate)
        extractor_class = workflow_class&.extractor_class || Seek::WorkflowExtractors::Base

        extractor_class.new(crate&.main_workflow&.source)
      end

      def abstract_cwl_extractor(crate)
        return @abstract_cwl_extractor if @abstract_cwl_extractor

        abstract_cwl = crate&.main_workflow_cwl&.source
        @abstract_cwl_extractor = abstract_cwl ? Seek::WorkflowExtractors::CWL.new(abstract_cwl) : nil
      end
    end
  end
end
