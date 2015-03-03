module Seek::ResearchObjects
  class JsonMetadata < Metadata
    include Singleton


    def metadata_content item
      json = {title:item.title,description:item.description}
      json[:assay_type]=item.assay_type_uri if item.respond_to?(:assay_type_uri)
      json[:technology_type]=item.technology_type_uri if item.respond_to?(:technology_type_uri)
      json[:contributor]=create_agent(item.contributor)
      if item.is_asset?
        blobs = asset_blobs(item).select{|blob| blob.file_exists?}
        json[:contains]=blobs.collect{|blob| blob.original_filename}
      end

      JSON.pretty_generate(json)
    end

    def metadata_filename
      "metadata.json"
    end

  end
end