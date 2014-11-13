module Seek
  module Ontologies
    class OntologyClass
      attr_reader :uri, :description, :label, :subclasses, :parents, :term_type

      alias_method :children, :subclasses

      include OntologyClassExtensionWithSuggestedType

      def initialize(uri, label = nil, description = nil, subclasses = [], parents = [], term_type = nil)
        @uri = uri
        validate_uri
        @description = description
        @label = label
        @subclasses = subclasses
        @parents = parents
        @term_type = term_type
      end

      def label
        @label ||= extract_label_from_uri_fragment
      end

      def descriptive_label
        label
      end

      # returns an array of all the classes, including this and traversal of the subclasses
      def flatten_hierarchy(clz = self)
        result = [clz]
        clz.subclasses.each do |sub_class|
          result += flatten_hierarchy(sub_class)
        end
        result
      end

      # returns a hash of all the classes from the hierarchy, including all subclasses, with the key being the URI as a string
      def hash_by_uri
        @hash_by_uri ||= begin
          result = {}
          flatten_hierarchy.each do |c|
            result[c.uri.to_s] = c
          end
          result
        end
      end

      # returns a hash of all the classes from the hierarchy, including all subclasses, with the key being the lowercase label
      def hash_by_label
        @hash_by_label ||= begin
          result = {}
          flatten_hierarchy.each do |c|
            result[c.label.downcase] = c
          end
          result
        end
      end

      private

      def validate_uri
        fail Exception.new('URI must be provided, as either as a string or RDF::URI type') if @uri.nil?
        @uri = RDF::URI.new(@uri) if @uri.is_a?(String)
        fail Exception.new('URI must be provided, as either as a string or RDF::URI type') unless @uri.kind_of?(RDF::URI)
      end

      def extract_label_from_uri_fragment
        (@uri.fragment || '').humanize
      end
    end
  end
end
