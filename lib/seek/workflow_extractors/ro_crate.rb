require 'rest-client'
require 'ro_crate'

module Seek
  module WorkflowExtractors
    class ROCrate < Base
      def initialize(io, main_workflow_class: nil)
        @io = io
        @main_workflow_class = main_workflow_class
      end

      def has_tests?
        open_crate do |crate|
          crate.test_suites.any?
        end
      rescue ::ROCrate::ReadException => e
        false
      end

      def can_render_diagram?
        open_crate do |crate|
          crate.main_workflow_diagram.present? || main_workflow_extractor(crate)&.can_render_diagram? || abstract_cwl_extractor(crate)&.can_render_diagram?
        end
      rescue ::ROCrate::ReadException => e
        false
      end

      def generate_diagram
        open_crate do |crate|
          return crate.main_workflow_diagram&.source&.read if crate.main_workflow_diagram

          extractor = main_workflow_extractor(crate)
          return extractor.generate_diagram if extractor&.can_render_diagram?

          extractor = abstract_cwl_extractor(crate)
          return extractor.generate_diagram if extractor&.can_render_diagram?

          return nil
        end
      rescue ::ROCrate::ReadException => e
        nil
      end

      def metadata
        open_crate do |crate|
          # Use CWL description
          m = if crate.main_workflow_cwl
                begin
                  abstract_cwl_extractor(crate).metadata
                rescue StandardError => e
                  Rails.logger.error('Error extracting abstract CWL:')
                  Rails.logger.error(e)
                  { errors: ["Couldn't parse abstract CWL"] }
                end
              else
                begin
                  main_workflow_extractor(crate).metadata
                rescue StandardError => e
                  Rails.logger.error('Error extracting workflow:')
                  Rails.logger.error(e)
                  { errors: ["Couldn't parse main workflow"] }
                end
              end
          m[:workflow_class_id] ||= main_workflow_class(crate)&.id

          # Metadata from crate
          if crate['keywords'] && m[:tags].blank?
            m[:tags] = crate['keywords'].is_a?(Array) ? crate['keywords'] : crate['keywords'].split(',').map(&:strip)
          end

          m[:title] = crate['name'] if crate['name'].present?
          m[:description] = crate['description'] if crate['description'].present?
          m[:license] = crate['license'] if crate['license'].present?

          other_creators = []
          authors = []
          [crate['author'], crate['creator']].each do |author_category|
            if author_category.present?
              author_category = author_category.split(',').map(&:strip) if author_category.is_a?(String)
              author_category = author_category.is_a?(Array) ? author_category : [author_category]
              author_category.each_with_index do |author_meta|
                author_meta = author_meta.dereference if author_meta.respond_to?(:dereference)
                if author_meta.is_a?(::ROCrate::ContextualEntity) && !author_meta.is_a?(::ROCrate::Person)
                  other_creators << author_meta['name'] if author_meta['name'].present?
                else
                  author = extract_author(author_meta)
                  authors << author unless author.blank?
                end
              end
            end
          end

          m[:other_creators] = other_creators.join(', ') if other_creators.any?
          authors.uniq!
          if authors.any?
            m[:assets_creators_attributes] ||= {}
            authors.each_with_index do |author, i|
              m[:assets_creators_attributes][i.to_s] = author.merge(pos: i)
            end
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
          if @io.respond_to?(:in_dir)
            @io.in_dir(dir)
            @opened_crate = ::ROCrate::WorkflowCrateReader.read(dir)
          else
            @opened_crate = ::ROCrate::WorkflowCrateReader.read_zip(@io.is_a?(ContentBlob) ? @io.data_io_object : @io, target_dir: dir)
          end
          yield @opened_crate
        end

        @opened_crate = nil

        v
      rescue StandardError => e
        raise ::ROCrate::ReadException.new("Couldn't read RO-Crate metadata.", e)
      end

      def diagram_extension
        open_crate do |crate|
          if crate&.main_workflow&.diagram
            return crate&.main_workflow&.diagram.id.split('.').last
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
