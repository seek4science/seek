module Seek
  module Ontologies

    class OntologyClass
      attr_reader :uri,:description,:label,:subclasses

      def initialize uri,label=nil,description=nil,subclasses=[]
        @uri = uri
        validate_uri
        @description = description
        @label = label
        @subclasses = subclasses
      end

      def label
        if @label.nil?
          @label = extract_label_from_uri
        end
        @label
      end

      private

      def validate_uri
        raise Exception.new("URI must be provided, as either as a string or RDF::URI type") if @uri.nil?
        @uri = RDF::URI.new(@uri) if @uri.is_a?(String)
        raise Exception.new("URI must be provided, as either as a string or RDF::URI type") unless @uri.kind_of?(RDF::URI)
      end

      def extract_label_from_uri
        @uri.fragment.humanize
      end
    end
  end
end