class SearchRdfController < ApplicationController

  def index

  end

  def search

    @repository = Seek::Rdf::RdfRepository.instance

    #   skip("these tests need a configured triple store setup") unless @repository.configured? TODO handle repository not set up/ accessable
    # WebMock.allow_net_connect!
    @graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph

    @rdf_search_query = params[:rdf_search_query]

    logger.info "ET search query"
    logger.info @rdf_search_query


    @rdf_search_query = Seek::Search::SearchTermFilter.filter @rdf_search_query

    downcase_query = @rdf_search_query.downcase


    if (!downcase_query.blank?) #TODO Also check if virtuoso is enabled

      q = @repository.query.select.where([:s, RDF::URI.new("http://purl.org/dc/terms/title"), downcase_query]).from(@graph)
      results = @repository.select(q)

      puts results.pretty_inspect

      @results=results
    end
  end
end
