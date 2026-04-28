module Seek
  module Rdf
    # Emits DCAT type assertions and dcat:Distribution blank nodes for SEEK resources.
    # DCAT class is determined by the resource's class name. A Distribution blank node
    # is emitted for any resource that has a non-empty ContentBlob attached.
    class DcatEmitter
      DCAT_CLASS_MAP = {
        'DataFile' => RDF::Vocab::DCAT.Dataset,
        'Assay' => RDF::Vocab::DCAT.Dataset,
        'Investigation' => RDF::Vocab::DCAT.Resource,
        'Study' => RDF::Vocab::DCAT.Resource
      }.freeze

      def initialize(resource, graph)
        @resource = resource
        @graph    = graph
      end

      def emit
        emit_dcat_type
        emit_distribution if distribution_applicable?
        @graph
      end

      private

      def emit_dcat_type
        dcat_class = DCAT_CLASS_MAP[@resource.class.name]
        return unless dcat_class

        @graph << [@resource.rdf_resource, RDF.type, dcat_class]
      end

      def distribution_applicable?
        @resource.respond_to?(:content_blob) &&
          @resource.content_blob.present? &&
          !@resource.content_blob.no_content?
      end

      def emit_distribution
        subject      = @resource.rdf_resource
        blob         = @resource.content_blob
        dist         = RDF::Node.new
        download_uri = RDF::URI("#{subject}/download")

        @graph << [subject, RDF::Vocab::DCAT.distribution, dist]
        @graph << [dist, RDF.type, RDF::Vocab::DCAT.Distribution]
        @graph << [dist, RDF::Vocab::DCAT.accessURL, download_uri]
        @graph << [dist, RDF::Vocab::DCAT.downloadURL, download_uri]

        emit_distribution_metadata(dist, blob)
      end

      def emit_distribution_metadata(dist, blob)
        if blob.file_size.to_i.positive?
          @graph << [dist, RDF::Vocab::DCAT.byteSize,
                     RDF::Literal.new(blob.file_size.to_s, datatype: RDF::Vocab::XSD.decimal)]
        end

        return unless blob.content_type.present?

        @graph << [dist, RDF::Vocab::DC.format, RDF::Literal.new(blob.content_type)]
      end
    end
  end
end
