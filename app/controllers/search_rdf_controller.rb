class SearchRdfController < ApplicationController
  include Seek::Rdf::RdfRepositoryStorage
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
      results = @repository.select(q).collect { |result| result[:s] }

      results.select { |result| result.is_a?(RDF::URI) }.collect { |result| result.to_s }.uniq

      puts "*** results ***"
      results.pretty_inspect
      puts "class"
      print(results[0].class.name)

      #    @results = []
      #   results.each { |result| @results.push(get_object_from_url(result)) }

      @results = get_active_records_from_urls(results)
      puts "*** @results ***"
      @results.pretty_inspect

      @results = select_authorised @results
    end

  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select { |el| el.can_view? }
  end

  #returns The active-record items that correspond to the given urls.
  #TODO refactor common part of this function and Seek::Rdf::RdfRepositoryStorage.related_items_from_sparql function
  def get_active_records_from_urls urls
    items = []
    if rdf_repository_configured?
      urls.each do |uri|
        begin
          puts uri
          route = SEEK::Application.routes.recognize_path(uri)
          puts route
          if !route.nil? && !route[:id].nil?
            klass = route[:controller].singularize.camelize.constantize
            puts klass
            id = route[:id]

            #TODO build a map of klass -> list of ids, then call find() for all of the same type at once (fewer db calls)
            items << klass.find(id)
          end
        rescue Exception => e
          puts e
        end
      end
    end
    items
  end

end
