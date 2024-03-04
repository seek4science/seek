module BioInd
  module FairData
    class Base
      attr_reader :identifier
      attr_reader :graph
      attr_reader :children

      def initialize(identifier, graph)
        @identifier = identifier
        @graph = graph
        @jerm = RDF::Vocabulary.new("http://jermontology.org/ontology/JERMOntology#")
        @children = []
      end

      def annotations
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [identifier, :type, :value]
        )

        query.execute.collect do |prop|
          [prop.type.to_s, prop.value.to_s]
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

      def fetch_children
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [identifier, @jerm.hasPart, :child]
        )

        query.execute.collect do |solution|
          solution.child
        end
      end

    end
  end
end