module BioInd
  module FairData
    class Base
      attr_reader :resource_uri
      attr_reader :graph
      attr_reader :children

      def initialize(resource_uri, graph)
        @resource_uri = resource_uri
        @graph = graph
        @jerm = RDF::Vocabulary.new("http://jermontology.org/ontology/JERMOntology#")
        @schema = RDF::Vocabulary.new("http://schema.org/")
        @children = []
      end

      def identifier
        find_annotation_value(@schema.identifier.to_s)
      end

      def title
        find_annotation_value(@schema.title) || find_annotation_value(@schema.name)
      end

      def description
        find_annotation_value(@schema.description)
      end

      def annotations
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, :type, :value]
        )

        query.execute.collect do |prop|
          [prop.type.to_s, prop.value.to_s]
        end
      end

      def find_annotation_value(property)
        annotations.detect do |ann|
          ann[0] == property
        end&.[](1)
      end

      def pp_annotations
        annotations.sort_by{|a| a[0]}.each do |pair|
          pp "#{pair[0]} -> #{pair[1]}"
        end
      end

      def populate
        fetch_children.collect do |child|
          add_child(child)
        end
      end

      def add_child(child)
        @children << child_class.new(child, graph)
        @children.last.populate
      end

      def datasets
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, @schema.dataset, :dataset]
        )
        query.execute.collect do |solution|
          BioInd::FairData::DataSet.new(solution.dataset, graph)
        end
      end

      def fetch_children
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, @jerm.hasPart, :child]
        )

        query.execute.collect do |solution|
          solution.child
        end
      end

    end
  end
end