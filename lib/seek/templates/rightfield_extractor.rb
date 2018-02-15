module Seek
  module Templates
    class RightfieldExtractor
      include RightField

      attr_reader :data_file, :rdf_graph

      def initialize(data_file)
        @data_file = data_file
        @rdf_graph = generate_rightfield_rdf_graph(data_file)
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

      def project
        id = seek_id_by_type(Project)
        Project.find_by_id(id) if id
      end

      def study
        id = seek_id_by_type(Study)
        Study.find_by_id(id) if id
      end

      def title
        value_for_property_and_index(:title, 0)
      end

      def description
        value_for_property_and_index(:description, 0)
      end

      def assay_title
        value_for_property_and_index(:title, 1)
      end

      def assay_description
        value_for_property_and_index(:description, 1)
      end

      def assay_assay_type_uri
        value_for_property_and_index(:hasType, 0)
      end

      def assay_technology_type_uri
        value_for_property_and_index(:hasType, 1)
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
