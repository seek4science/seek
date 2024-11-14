module Seek
  module ResearchObjects
    # top level module or the generation of research objects
    class Generator
      include Utils

      DEFAULT_FILENAME = 'ro-bundle.zip'.freeze

      def initialize(resource)
        @resource = resource
      end

      # :call-seq
      # generate(resource, file) -> File
      # generate(resource) ->
      #
      # generates an RO-Bundle for the given resource.
      # if a file objects is passed in then the bundle in created to the file,
      # overwriting previous content
      # if no file is provided, then a temporary file is created
      # using the name defined by #DEFAULT_FILENAME
      # in both cases the file is returned
      #
      def generate(file = nil)
        file ||= temp_file(DEFAULT_FILENAME)
        ROBundle::File.create(file) do |ro|
          @bundle = ro
          bundle(@resource)
        end
        file
      end

      # Recursively store metadata/files of this resource and its children.
      def bundle(resource, bundled = Set.new, parents = [])
        return if bundled.include?(resource)
        return unless resource.permitted_for_research_object?
        bundled << resource
        store_reference(resource, parents)
        store_metadata(resource, parents)
        store_files(resource, parents) if resource.is_asset?
        children(resource).each do |child|
          bundle(child, bundled, (parents + [resource]))
        end
      end

      def children(resource)
        case resource
        when Investigation
          resource.studies + resource.assets
        when Study
          resource.assays + resource.assets
        when Assay
          resource.assets
        else
          []
        end
      end

      def included_items(resource = @resource, included = Set.new, excluded = Set.new, parent_excluded = false)
        return if included.include?(resource) || excluded.include?(resource)
        permitted = !parent_excluded && resource.permitted_for_research_object?
        if permitted
          included << resource
        else
          excluded << resource
        end
        children(resource).each do |child|
          included_items(child, included, excluded, !permitted)
        end

        [included, excluded]
      end

      private

      # the current metadata handlers - JSON and RDF
      def metadata_handlers
        [Seek::ResearchObjects::RdfMetadata.instance, Seek::ResearchObjects::JSONMetadata.instance]
      end

      # generates and stores the metadata for the item, using the handlers
      # defined by #metdata_handlers
      def store_metadata(item, parents = [])
        metadata_handlers.each { |handler| handler.store(@bundle, item, parents) }
      end

      # stores a reference to the `resource` in the RO manifest
      def store_reference(resource, parents = [])
        @bundle.manifest.aggregates << ROBundle::Aggregate.new(:uri => '/' + resource.research_object_package_path(parents),
                                                               'pav:importedFrom' => item_uri(resource))
      end

      # stores the actual physical files defined by the contentblobs for the asset, and adds the appropriate
      # aggregation to the RO manifest
      def store_files(asset, parents = [])
        asset.all_content_blobs.each do |blob|
          store_blob_file(asset, blob, parents) if blob.file_exists?
        end

        if asset.respond_to?(:model_image) && asset.model_image
          store_blob_file(asset, asset.model_image, parents)
        end
      end

      # stores a content blob file, added the aggregate to the manifest
      def store_blob_file(asset, blob, parents = [])
        path = resolve_entry_path(asset, blob, parents)
        @bundle.add(path, blob.filepath, aggregate: true)
      end

      # resolves the entry path, to avoid duplicates. If an asset has multiple files
      # with some the same name, a "c-" is prepended t the file name, where c starts at 1 and increments
      def resolve_entry_path(asset, blob, parents = [])
        path = File.join(asset.research_object_package_path(parents), blob.original_filename)
        while @bundle.find_entry(path)
          c ||= 1
          path = File.join(asset.research_object_package_path(parents), "#{c}-#{blob.original_filename}")
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
