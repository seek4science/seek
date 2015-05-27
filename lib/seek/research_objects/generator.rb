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
          gather_entries(investigation).each do |entry|
            store_metadata(bundle, entry)
            store_files(bundle, entry) if entry.is_asset?
          end
          bundle.created_on = Time.now
        end
        file
      end

      private

      # collects the entries contained by the investigation for inclusion in
      # the research object
      def gather_entries(investigation)
        entries = [investigation] + [investigation.studies] + [investigation.assays] + [investigation.assets]
        entries.flatten.select(&:permitted_for_research_object?)
      end

      # generates and stores the metadata for the item, using the handlers
      # defined by #metdata_handlers
      def store_metadata(bundle, item)
        metadata_handlers.each { |handler| handler.store(bundle, item) }
      end

      # the current metadata handlers - JSON and RDF
      def metadata_handlers
        [Seek::ResearchObjects::RdfMetadata.instance, Seek::ResearchObjects::JSONMetadata.instance]
      end

      # stores the actual physical files defined by the contentblobs for the asset, and adds the appropriate
      # aggregation to the RO manifest
      def store_files(bundle, asset)
        asset.all_content_blobs.each do |blob|
          store_blob_file(bundle, asset, blob) if blob.file_exists?
        end

        if asset.respond_to?(:model_image) && asset.model_image
          store_blob_file(bundle, asset, asset.model_image)
        end
      end

      # stores a content blob file, added the aggregate to the manifest
      def store_blob_file(bundle, asset, blob)
        path = File.join(asset.research_object_package_path, blob.original_filename)
        bundle.add(path, blob.filepath, aggregate: true)
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
