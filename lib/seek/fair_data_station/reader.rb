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

      def candidates_for_extended_metadata(path)
        inv = parse_graph(path).first
        study = inv&.studies&.first
        obs_unit = study&.observation_units&.first
        assay = study&.assays&.first
        [inv, study, obs_unit, assay].compact.select do |type|
          type.all_additional_potential_annotation_predicates.any?
        end
      end
    end
  end
end
