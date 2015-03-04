module Seek::ResearchObjects
  class JsonMetadata < Metadata
    include Singleton

    def metadata_content item
      json = {title: item.title, description: item.description}
      json[:assay_type]=item.assay_type_uri if item.respond_to?(:assay_type_uri)
      json[:technology_type]=item.technology_type_uri if item.respond_to?(:technology_type_uri)
      json[:contributor]=create_agent(item.contributor)
      if item.is_asset?
        json[:contains] = contains(item)

      end
      JSON.pretty_generate(json)
    end

    def metadata_filename
      "metadata.json"
    end

    private

    def contains(asset)
      asset_blobs(asset).collect do |blob|
        if blob.file_exists?
          File.join(asset.package_path,blob.original_filename)
        elsif blob.url
          blob.url
        end
      end.compact
    end
  end

end
