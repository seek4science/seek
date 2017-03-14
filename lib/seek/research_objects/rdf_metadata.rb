module Seek
  module ResearchObjects
    # proves the content for the RDF metadata of an item being included in a Research Object.
    # the RDF is generated using the standard RDF generation Seek::RDF::RDFGeneration
    class RdfMetadata < Metadata
      include Singleton

      def metadata_content(item, _parents = [])
        item.to_rdf
      end

      def metadata_filename
        'metadata.rdf'
      end
    end
  end
end
