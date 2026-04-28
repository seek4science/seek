module Seek
  module Rdf
    # Emits RDF triples for a SEEK resource's extended metadata.
    # For each attribute with a pid, uses RdfMapping to build the correct
    # RDF::Term (plain literal, language-tagged, XSD-typed, or IRI).
    # Attributes without a pid fall back to the seekh: namespace.
    class ExtendedMetadataEmitter
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
        mapping   = RdfMapping.from_attribute(attr)

        Array.wrap(value).each do |v|
          rdf_object = mapping.build_rdf_object(v)
          @graph << [subject, predicate, rdf_object] if rdf_object
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
