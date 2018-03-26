module Seek
  module Templates
    # Base class for handling of extracting and interpreting metadata from within a Rightfield Template
    class RightfieldExtractor
      include RightField

      attr_reader :rdf_graph

      def initialize(source_data_file)
        @rdf_graph = generate_rightfield_rdf_graph(source_data_file)
      end

      private

      def project
        id = seek_id_by_type(Project)
        Project.find_by_id(id) if id
      end

      def value_for_property_and_index(property, index)
        solution = query_solutions_for_property(property)[index]
        solution.result.value if solution
      end

      def query_solutions_for_property(property)
        RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab[property], :result]
        end
      end

      def seek_id_by_type(type)
        uri = seek_id_uris.find { |id| id.include?("/#{type.name.tableize}/") }
        uri.split('/').last if uri
      end

      def seek_id_uris
        RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.seekID, :seek_id]
        end.collect(&:seek_id).collect(&:value).select do |uri|
          uri =~ URI::DEFAULT_PARSER.regexp[:ABS_URI] # reject invalid URI's
        end.select do |uri|
          uri_matches_host?(uri) # reject those that don't match the configured host
        end
      end

      def uri_matches_host?(uri)
        URI.parse(uri).host == URI.parse(Seek::Config.site_base_host).host
      end
    end
  end
end
