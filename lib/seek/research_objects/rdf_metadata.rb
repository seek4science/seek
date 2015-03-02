module Seek::ResearchObjects
  class RdfMetadata < Metadata
    include Singleton
    
    def metadata_content item
      item.to_rdf
    end

    def metadata_filename
      "metadata.rdf"
    end

  end
end