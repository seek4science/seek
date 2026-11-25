# Helpers for tests that use a configured triple store
module TripleStoreTestHelper
  # removes all statements from the public and private graphs, and drops every item graph and the index graph
  def clear_triple_store(repository)
    config = repository.get_configuration
    [config.private_graph, config.public_graph].compact.each do |graph|
      q = repository.query.delete(%i[s p o]).graph(RDF::URI(graph)).where(%i[s p o])
      repository.delete(q)
    end

    index_graph = repository.item_index_graph_uri
    q = repository.query.select.distinct.where([:g, RDF::Vocab::DC.isPartOf, :o]).from(index_graph)
    item_graphs = repository.select(q).map { |result| result[:g] }
    (item_graphs + [index_graph]).each { |graph| repository.update("DROP SILENT GRAPH #{graph.to_base}") }
  end
end
