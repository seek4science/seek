module Seek
  module ResearchObjects
    # top level module or the generation of research objects
    class Generator
      include Singleton
      include Utils

      DEFAULT_FILENAME = 'ro-bundle.zip'

      # :call-seq
      # generate(investigation,file) -> File
      # generate(investigation) ->
      #
      # generates an RO-Bundle for the given investigation.
      # if a file objects is passed in then the bundle in created to the file,
      # overwriting previous content
      # if no file is provided, then a temporary file is created
      # using the name defined by #DEFAULT_FILENAME
      # in both cases the file is returned
      #
      def generate(investigation, file = nil)
        file ||= temp_file(DEFAULT_FILENAME)
        ROBundle::File.create(file) do |bundle|
          bundle.created_by = create_agent
          aggregate_resource(bundle, investigation)
          bundle.created_on = Time.now
        end
        file
      end

      private

      # Traverse ISA + assets tree and aggregate metadata and files
      def aggregate_resource(bundle, resource, base_path = nil)
        if true || resource.permitted_for_research_object?
          if base_path.blank?
            path = resource.ro_package_path_fragment
          else
            path = File.join(base_path, resource.ro_package_path_fragment)
          end
          # Add metadata and content to RO
          store_metadata(bundle, resource, path)
          store_files(bundle, resource, path) if resource.is_asset?
          # Recurse over child resources
          child_resources(resource).each do |child_resource|
            aggregate_resource(bundle, child_resource, path)
          end
        end
      end

      # I -> S -> A -> Assets
      def child_resources(resource)
        case resource
          when Investigation
            resource.studies
          when Study
            resource.assays
          when Assay
            resource.assets
          else
            []
        end
      end

      # generates and stores the metadata for the item, using the handlers
      # defined by #metdata_handlers
      def store_metadata(bundle, item, path = nil)
        metadata_handlers.each { |handler| handler.store(bundle, item, path) }
      end

      # the current metadata handlers - JSON and RDF
      def metadata_handlers
        [Seek::ResearchObjects::RdfMetadata.instance, Seek::ResearchObjects::JSONMetadata.instance]
      end

      # stores the actual physical files defined by the contentblobs for the asset, and adds the appropriate
      # aggregation to the RO manifest
      def store_files(bundle, asset, path = nil)
        asset.all_content_blobs.each do |blob|
          store_blob_file(bundle, asset, blob, path) if blob.file_exists?
        end

        if asset.respond_to?(:model_image) && asset.model_image
          store_blob_file(bundle, asset, asset.model_image, path)
        end
      end

      # stores a content blob file, added the aggregate to the manifest
      def store_blob_file(bundle, asset, blob, path = nil)
        path = resolve_entry_path(bundle, asset, blob, path)
        bundle.add(path, blob.filepath, aggregate: true)
      end

      #resolves the entry path, to avoid duplicates. If an asset has multiple files
      #with some the same name, a "c-" is prepended t the file name, where c starts at 1 and increments
      def resolve_entry_path(bundle, asset, blob, base_path = nil)
        base_path ||= asset.research_object_package_path
        path = File.join(base_path, blob.original_filename)
        while bundle.find_entry(path)
          c ||= 1
          path = File.join(base_path, "#{c}-#{blob.original_filename}")
          c += 1
        end
        path
      end

      # create an empty temp file, and return the opened file ready for writing.
      # unlike Tempfile, the temporary file is persisted until it is explicitly deleted.
      def temp_file(filename, prefix = '')
        dir = Dir.mktmpdir(prefix)
        open(File.join(dir, filename), 'w+')
      end
    end
  end
end
