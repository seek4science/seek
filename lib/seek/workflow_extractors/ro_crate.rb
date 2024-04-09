require 'rest-client'
require 'ro_crate'

module Seek
  module WorkflowExtractors
    class ROCrate < ROLike
      def has_tests?
        open_crate do |crate|
          crate.test_suites.any?
        end
      rescue ::ROCrate::ReadException => e
        false
      end

      def can_render_diagram?
        open_crate do
          super
        end
      rescue ::ROCrate::ReadException => e
        false
      end

      def generate_diagram
        open_crate do
          super
        end
      rescue ::ROCrate::ReadException => e
        nil
      end

      def metadata
        open_crate do |crate|
          meta = super
          metadata_from_crate(crate, meta)
        end
      end

      def open_crate
        if @opened_crate
          v = yield @opened_crate
          return v
        end

        v = Dir.mktmpdir('ro-crate') do |dir|
          if @obj.respond_to?(:in_dir)
            @obj.in_dir(dir)
            @opened_crate = ::ROCrate::WorkflowCrateReader.read(dir)
          else
            @opened_crate = ::ROCrate::WorkflowCrateReader.read_zip(@obj.is_a?(ContentBlob) ? @obj.data_io_object : @obj, target_dir: dir)
          end
          yield @opened_crate
        end

        @opened_crate = nil

        v
      rescue StandardError => e
        raise ::ROCrate::ReadException.new("Couldn't read RO-Crate metadata.", e)
      end

      def diagram_extension
        open_crate do
          super
        end
      rescue ::ROCrate::ReadException => e
        false
      end

      private

      # Metadata extracted from the RO-Crate object (i.e. what's in ro-crate-metadata.json)
      def metadata_from_crate(crate, m)
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

        source_url = crate.source_url
        if source_url
          m.merge!(extract_source_metadata(ContentBlob.remote_content_handler_for(source_url)))
          m[:source_link_url] ||= source_url # Use plain source URL if handler doesn't have something more appropriate
        end

        m
      end

      def opened_crate
        @opened_crate || raise('Crate not opened')
      end

      def main_workflow_path
        opened_crate&.main_workflow&.id
      end

      def abstract_cwl_path
        opened_crate&.main_workflow_cwl&.id
      end

      def diagram_path
        opened_crate&.main_workflow_diagram&.id
      end

      def file_exists?(path)
        !!(opened_crate.dereference(path) || opened_crate.find_entry(path))
      end

      # Path could be a path (or URL if remote) of an Entity in the crate, or just a path to a file that may not have an associated Entity.
      def file(path)
        file = opened_crate.dereference(path)
        if file
          file.source
        else
          opened_crate.find_entry(path)
        end
      end

      def licensee_project
        @licensee_project ||= ::Licensee::Projects::RoCrateProject.new(opened_crate)
      end

      def main_workflow_class
        super || WorkflowClass.match_from_metadata(opened_crate&.main_workflow&.programming_language&.properties || {})
      end
    end
  end
end
