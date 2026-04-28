module Seek
  module Rdf
    # Value object that converts an attribute's RDF configuration + a Ruby value
    # into the correct RDF::Term.
    #
    # Value types (stored on SampleAttributeType#rdf_value_type):
    #   "literal"       → plain RDF::Literal (default; backwards-compatible)
    #   "lang_literal"  → language-tagged literal (@en by default)
    #   "typed_literal" → datatype-tagged literal (rdf_datatype must be set)
    #   "iri"           → RDF::URI; falls back to plain literal if value is not a valid IRI
    class RdfMapping
      DEFAULT_LANGUAGE = :en

      attr_reader :predicate, :value_type, :datatype

      def initialize(predicate:, value_type: nil, datatype: nil)
        @predicate  = RDF::URI(predicate.to_s)
        @value_type = SampleAttributeType::RDF_VALUE_TYPES.include?(value_type) ? value_type : 'literal'
        @datatype   = datatype.present? ? RDF::URI(datatype.to_s) : nil
      end

      # Builds the RDF object term for the given value.
      # Returns nil when the value is blank.
      def build_rdf_object(value)
        return nil if value.nil? || value.to_s.strip.empty?

        case value_type
        when 'iri'           then build_iri(value)
        when 'typed_literal' then build_typed_literal(value)
        when 'lang_literal'  then build_lang_literal(value)
        else
          build_plain_literal(value)
        end
      end

      # Builds a mapping from any attribute that has pid and belongs_to sample_attribute_type.
      # Works for both ExtendedMetadataAttribute and SampleAttribute.
      def self.from_attribute(attribute)
        sat = attribute.sample_attribute_type
        new(
          predicate: attribute.pid,
          value_type: sat&.rdf_value_type,
          datatype: sat&.rdf_datatype
        )
      end

      private

      def build_iri(value)
        uri = RDF::URI(value.to_s)
        if uri.valid?
          uri
        else
          Rails.logger.warn "[RdfMapping] Invalid IRI '#{value}' for predicate #{predicate} — emitting as plain literal"
          build_plain_literal(value)
        end
      end

      def build_typed_literal(value)
        if datatype.present?
          RDF::Literal.new(value.to_s, datatype: datatype)
        else
          Rails.logger.warn "[RdfMapping] typed_literal for #{predicate} has no rdf_datatype — " \
                             'emitting as plain literal'
          build_plain_literal(value)
        end
      end

      def build_lang_literal(value)
        RDF::Literal.new(value.to_s, language: DEFAULT_LANGUAGE)
      end

      def build_plain_literal(value)
        RDF::Literal.new(value.to_s)
      end
    end
  end
end
