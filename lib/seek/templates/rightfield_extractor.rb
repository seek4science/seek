module Seek
  module Templates
    class RightfieldExtractor
      include RightField

      attr_reader :data_file, :rdf_graph

      def initialize(data_file)
        @data_file = data_file
        @rdf_graph = generate_rightfield_rdf_graph(data_file)
        @rdf_graph.each do |s|
          puts s.to_s
        end
      end

      def populate
        data_file.title = title
        data_file.description = description
        data_file.projects = [project] if project
      end

      def title
        solutions = RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.title, :title]
        end
        solutions.first.title.value if solutions.any?
      end

      def description
        solutions = RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.description, :description]
        end
        solutions.first.description.value if solutions.any?
      end

      def project
        id = seek_id_by_type(Project)
        Project.find_by_id(id) if id
      end

      private

      def seek_id_by_type(type)
        uri = seek_ids.find { |id| id.include?("/#{type.name.tableize}/") }
        uri.split('/').last if uri
      end

      def seek_ids
        RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.seekID, :seek_id]
        end.collect(&:seek_id).collect(&:value)
      end
    end
  end
end
