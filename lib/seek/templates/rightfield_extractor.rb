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

      def populate_assay(assay)
        unless assay_title.blank?
          assay.title = assay_title
          assay.description = assay_description
          assay.assay_type_uri = assay_assay_type_uri
          assay.technology_type_uri = assay_technology_type_uri
          assay.study = study if study
        end
      end

      private

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

      def study
        id = seek_id_by_type(Study)
        Study.find_by_id(id) if id
      end

      def assay_title
        solutions = RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.title, :title]
        end
        solutions[1].title.value if solutions.count > 1
      end

      def assay_description
        solutions = RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.description, :description]
        end
        solutions[1].description.value if solutions.count > 1
      end

      def assay_assay_type_uri
        solutions = RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.hasType, :type]
        end
        solutions.first.type.value if solutions.any?
      end

      def assay_technology_type_uri
        solutions = RDF::Query.execute(@rdf_graph) do
          pattern [:s, Seek::Rdf::JERMVocab.hasType, :type]
        end
        solutions[1].type.value if solutions.count > 1
      end

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
