require 'rdf'
require 'rdf/turtle'
require 'sparql/client'

module Seek
  module FairDataStation
    class Reader
      def parse_graph(path)
        graph = RDF::Graph.load(path, format: :ttl)
        sparql = SPARQL::Client.new(graph)
        jerm = RDF::Vocabulary.new('http://jermontology.org/ontology/JERMOntology#')

        query = sparql.select.where(
          [:inv, RDF.type, jerm.[]('Investigation')]
        )
        query.execute.collect do |inv|
          inv = Seek::FairDataStation::Investigation.new(inv.inv, graph)
          inv.populate
          inv
        end
      end
    end
  end
end
