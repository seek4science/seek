module Seek::ResearchObjects

  class Generator
    include Singleton
    include Utils

    # :call-seq
    # generate(investigation,file) -> File
    # generate(investigation) ->
    #
    # generates an RO-Bundle for the given investigation.
    # if a file objects is passed in then the bundle in created to the file, overwriting previous content
    # if no file is provided, then a temporary file is created
    # in both cases the file is returned
    #
    def generate(investigation,file=nil)
      file ||= temp_file("ro-bundle.zip")
      ROBundle::File.create(file) do |bundle|
        bundle.created_by=create_agent
        gather_entries(investigation).each do |entry|
          describe_metadata(bundle,entry)
          store_files(bundle,entry) if entry.is_asset?
        end
        bundle.created_on=Time.now
      end

      return file
    end

    private

    def gather_entries(investigation)
      entries = [investigation] + [investigation.studies] + [investigation.assays] + [investigation.assets]
      entries.flatten.select{|entry| entry.permitted_for_research_object?}
    end

    def describe_metadata bundle, item
      Seek::ResearchObjects::RdfMetadata.instance.store(bundle,item)
      Seek::ResearchObjects::JSONMetadata.instance.store(bundle,item)
    end

    def store_files(bundle,asset)
      blobs = asset_blobs(asset)
      blobs.each do |blob|
        store_blob_file(bundle,asset,blob) if blob.file_exists?
      end

      if asset.respond_to?(:model_image) && asset.model_image
        store_image_file(bundle,asset,asset.model_image)
      end
    end

    def store_blob_file(bundle,asset,blob)
      path=File.join(asset.package_path,blob.original_filename)
      bundle.add(path,blob.filepath,:aggregate=>true)
    end

    def store_image_file(bundle,asset,model_image)
      path=File.join(asset.package_path,model_image.original_filename)
      bundle.add(path,model_image.file_path,:aggregate=>true)
    end

  end
end