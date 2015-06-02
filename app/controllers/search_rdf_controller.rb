class SearchRdfController < ApplicationController

  def index

  end

  def search

    # skip("these tests need a configured triple store setup") unless @repository.configured?
    # TODO handle repository not set up/ accessable
    # WebMock.allow_net_connect!

    @repository = Seek::Rdf::RdfRepository.instance
    @graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph
    has_associated_item_uri = RDF::URI.new("http://www.mygrid.org.uk/ontology/JERMOntology#hasAssociatedItem")

    @sugar_query = params[:sugar_query]
    @factor_query = params[:factor_query]

    logger.info "ET search query"
    logger.info @sugar_query
    logger.info @factor_query

    @list_of_queries = []

    if (!@sugar_query.nil?)
      @sugar_query = Seek::Search::SearchTermFilter.filter @sugar_query

      if (!@sugar_query.blank?) #TODO Also check if virtuoso is enabled
        # http://www.semanticweb.org/eilidhtroup/ontologies/2015/2/sugar#glucose
        sugarQuery = RDF::URI.new("http://www.semanticweb.org/eilidhtroup/ontologies/2015/2/sugar##{@sugar_query}")
        @list_of_queries.push([:s, has_associated_item_uri, sugarQuery])
      end
    end

    if (!@factor_query.nil?)
      @factor_query = Seek::Search::SearchTermFilter.filter @factor_query

      if (!@factor_query.blank?) #TODO Also check if virtuoso is enabled
        # http://www.semanticweb.org/eilidhtroup/ontologies/2015/2/sugar#glucose
        factorQuery = RDF::URI.new("http://www.mygrid.org.uk/ontology/JERMOntology##{@factor_query}")
        @list_of_queries.push([:s, has_associated_item_uri, factorQuery])
      end
    end
#    q = @repository.query.select.where([:s, RDF::URI.new("http://purl.org/dc/terms/hasVersion"), '2'],
#                                      [:s, RDF::URI.new("http://purl.org/dc/terms/description"), 'this is data file 1']).from(@graph)

    puts "@list_of_queries"
    puts @list_of_queries
    @list_of_queries.pretty_inspect

    unless (@list_of_queries.empty?)
      # do query
      q = @repository.query.select.where(*@list_of_queries).from(@graph)
      results = @repository.select(q)

      puts "***** Results ******"
      puts results.pretty_inspect

      @results = []
      results.each { |result| @results.push(get_object_from_url(result)) }

      @results = select_authorised @results
    end

  end

  # @param [RDF::URI] url
  def get_object_from_url url
    url_string = url.[](:s).to_str
    class_string = url_string.split('/')[-2]
    object_id = url_string.split('/')[-1]

    #TODO build a map of class_string -> list of ids
    # Then get all of each type from a single query.
    class_string.camelize.singularize.constantize.find_by_id(object_id)
  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select { |el| el.can_view? }
  end
end
