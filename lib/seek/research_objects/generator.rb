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
      entries.flatten
    end

    def describe_metadata bundle, item
      tmpfile = temp_file("metadata.rdf","ro-bundle-item-metadata")
      tmpfile << item.to_rdf
      tmpfile.close

      targetpath = File.join(item.package_path,"metadata.rdf")
      bundle.add(targetpath,tmpfile,:aggregate=>false)

      an = ROBundle::Annotation.new(item.rdf_resource.to_uri.to_s,targetpath)
      an.created_on=Time.now
      an.created_by=create_agent
      bundle.add_annotation(an)
    end

    def store_files(bundle,asset)
      blobs = asset_blobs(asset)
      blobs.each do |blob|
        store_blob_file(bundle,asset,blob) if blob.file_exists?
      end
    end

    def store_blob_file(bundle,asset,blob)
      path=File.join(asset.package_path,blob.original_filename)
      bundle.add(path,blob.filepath,:aggregate=>true)
    end

    def asset_blobs(asset)
      asset.respond_to?(:content_blob) ? [asset.content_blob] : asset.content_blobs
    end

  end
end