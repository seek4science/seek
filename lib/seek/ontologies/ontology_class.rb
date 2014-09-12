module Seek
  module Ontologies

    class OntologyClass
      attr_reader :uri,:description,:label,:subclasses,:parents, :term_type


      alias_method :children, :subclasses

      def initialize uri,label=nil,description=nil, subclasses=[],parents=[], term_type=nil
        @uri = uri
        validate_uri
        @description = description
        @label = label
        @subclasses = subclasses
        @parents = parents
        @term_type = term_type
      end

      def label
        if @label.nil?
          @label = extract_label_from_uri_fragment
        end
        @label
      end


      #returns an array of all the classes, inluding this and traversal of the subclasses
      def flatten_hierarchy c=self
        result = [c]
        c.subclasses.each do |s|
          result += flatten_hierarchy(s)
        end
        result
      end

      #returns a hash of all the classes from the hierarchy, including all subclasses, with the key being the URI as a string
      def hash_by_uri
        @hash_by_uri ||= begin
          result = {}
          flatten_hierarchy.each do |c|
            result[c.uri.to_s]=c
          end
          result
        end
      end

      #returns a hash of all the classes from the hierarchy, including all subclasses, with the key being the lowercase label
      def hash_by_label
        @hash_by_label ||= begin
          result = {}
          flatten_hierarchy.each do |c|
            result[c.label.downcase]=c
          end
          result
        end
      end

      private

      def validate_uri
        raise Exception.new("URI must be provided, as either as a string or RDF::URI type") if @uri.nil?
        @uri = RDF::URI.new(@uri) if @uri.is_a?(String)
        raise Exception.new("URI must be provided, as either as a string or RDF::URI type") unless @uri.kind_of?(RDF::URI)
      end

      def extract_label_from_uri_fragment
        (@uri.fragment || "").humanize
      end
    end
  end
end