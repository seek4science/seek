module Seek
  module Rdf
    # Emits RDF triples for a SEEK resource's extended metadata.
    # For each attribute with a pid, uses RdfMapping to build the correct
    # RDF::Term (plain literal, language-tagged, XSD-typed, or IRI).
    # Attributes backed by a linked_extended_metadata_type are emitted as
    # RDF blank nodes, with sub-properties from the nested EMT's attributes.
    # Attributes without a pid fall back to the seekh: namespace.
    class ExtendedMetadataEmitter
      # Maps known predicate URIs to the rdf:type of the blank node they introduce.
      BLANK_NODE_TYPE_MAP = {
        'http://purl.org/dc/terms/temporal' => RDF::URI('http://purl.org/dc/terms/PeriodOfTime'),
        'http://healthdataportal.eu/ns/health#retentionPeriod' => RDF::URI('http://purl.org/dc/terms/PeriodOfTime'),
        'http://www.w3.org/ns/dcat#contactPoint' => RDF::URI('http://www.w3.org/2006/vcard/ns#Kind'),
        'https://w3id.org/dpv#hasLegalBasis' => RDF::URI('https://w3id.org/dpv#LegalBasis'),
        'https://w3id.org/dpv#hasPurpose' => RDF::URI('https://w3id.org/dpv#Purpose'),
        'http://healthdataportal.eu/ns/health#hdab' => RDF::URI('http://xmlns.com/foaf/0.1/Agent')
      }.freeze

      def initialize(resource, graph)
        @resource = resource
        @graph    = graph
      end

      def emit
        return @graph unless extended_metadata_present?

        subject = @resource.rdf_resource
        @resource.extended_metadata.extended_metadata_type.extended_metadata_attributes.each do |attr|
          emit_attribute(subject, attr)
        end

        @graph
      end

      private

      def extended_metadata_present?
        @resource.respond_to?(:extended_metadata) &&
          @resource.extended_metadata&.extended_metadata_type.present?
      end

      def emit_attribute(subject, attr)
        predicate = predicate_for(attr)
        value     = @resource.extended_metadata.get_attribute_value(attr)

        if attr.sample_attribute_type&.linked_extended_metadata_or_multi?
          Array.wrap(value).each { |v| emit_blank_node(subject, predicate, attr, v) }
        else
          emit_scalar(subject, predicate, attr, value)
        end
      end

      def emit_scalar(subject, predicate, attr, value)
        mapping = RdfMapping.from_attribute(attr)
        Array.wrap(value).each do |v|
          rdf_object = mapping.build_rdf_object(v)
          @graph << [subject, predicate, rdf_object] if rdf_object
        end
      end

      def emit_blank_node(subject, predicate, attr, data)
        data = data.data if data.respond_to?(:data)
        data = data.to_h if data.is_a?(Seek::JSONMetadata::Data)
        return unless data.is_a?(Hash) && data.any?

        nested = collect_nested_triples(attr.linked_extended_metadata_type, data)
        return if nested.empty?

        blank = RDF::Node.new
        @graph << [subject, predicate, blank]
        @graph << [blank, RDF.type, BLANK_NODE_TYPE_MAP[predicate.to_s]] if BLANK_NODE_TYPE_MAP.key?(predicate.to_s)
        nested.each { |pred, obj| @graph << [blank, pred, obj] }
      end

      def collect_nested_triples(linked_emt, data)
        [].tap do |triples|
          linked_emt.extended_metadata_attributes.each do |nested_attr|
            nested_val = data[nested_attr.accessor_name]
            mapping    = RdfMapping.from_attribute(nested_attr)
            Array.wrap(nested_val).each do |v|
              rdf_object = mapping.build_rdf_object(v)
              triples << [predicate_for(nested_attr), rdf_object] if rdf_object
            end
          end
        end
      end

      def predicate_for(attr)
        if attr.pid.present?
          RDF::URI(attr.pid)
        else
          slug = attr.title.to_s.parameterize(separator: '_')
          Rails.logger.warn "[ExtendedMetadataEmitter] Attribute '#{attr.title}' has no pid — " \
                             "emitting as seekh:#{slug}"
          SEEKHVocab[slug]
        end
      end
    end
  end
end
