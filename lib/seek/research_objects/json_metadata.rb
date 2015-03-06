module Seek::ResearchObjects
  class JsonMetadata < Metadata
    include Singleton

    def metadata_content item
      json={id: item.id}
      [:title, :description, :assay_type_uri, :technology_type_uri, :version].each do |method|
        json[method]=item.send(method) if item.respond_to?(method)
      end

      json[:contributor]=create_agent(item.contributor)
      if item.is_asset?
        json[:contains] = contained_files(item)
      end
      JSON.pretty_generate(json)
    end

    def metadata_filename
      "metadata.json"
    end

    private

    def contained_files(asset)
      blobs = asset_blobs(asset).collect do |blob|
        if blob.file_exists?
          File.join(asset.package_path,blob.original_filename)
        elsif blob.url
          blob.url
        end
      end.compact
      if asset.respond_to?(:model_image) && asset.model_image
        blobs << File.join(asset.package_path,asset.model_image.original_filename)
      end
      blobs
    end
  end

end
