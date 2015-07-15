class SearchRdfController < ApplicationController
  include Seek::Rdf::RdfRepositoryStorage
  def index

  end

  def search
    @sugar_query = nil
    @strain_query = nil
    @results = nil

    # skip("these tests need a configured triple store setup") unless @repository.configured?
    # TODO handle repository not set up/ accessable
    # WebMock.allow_net_connect!

    @repository = Seek::Rdf::RdfRepository.instance
    @graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph
    associated_with = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#associatedWith")
    contains = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#contains")
    derived_from = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#derivedFrom")
    @sugar_query = params[:sugar_query]
    @strain_query = params[:strain_query]

    logger.info "rdf search query"
    logger.info @sugar_query
    logger.info @strain_query

    @list_of_queries = []

    #   q = @repository.query.select.where(
    #       [:s, RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#associatedWith"), :p],
    #       [:p, RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#contains"),
    #        RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/sugar/Raf")],
    #       [:p, RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#derivedFrom"),
    #        RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/strain/GAL1")]).from(@graph)

    if (!@sugar_query.nil?)
      @sugar_query = Seek::Search::SearchTermFilter.filter @sugar_query

      if (!@sugar_query.blank?) #TODO Also check if virtuoso is enabled
        # http://www.semanticweb.org/eilidhtroup/ontologies/2015/2/sugar#glucose
        @sugar_query.capitalize!
        sugarQuery = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/sugar/#{@sugar_query}")
        @list_of_queries.push([:sample, contains, sugarQuery])
      end
    end

    if (!@strain_query.nil?)
      @strain_query = Seek::Search::SearchTermFilter.filter @strain_query
      @strain_query.upcase!
      if (!@strain_query.blank?) #TODO Also check if virtuoso is enabled
        # http://www.semanticweb.org/eilidhtroup/ontologies/2015/2/sugar#glucose
        strainQuery = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/strain/#{@strain_query}")
        @list_of_queries.push([:sample, derived_from, strainQuery])
      end
    end

    puts "@list_of_queries"
    puts @list_of_queries
    @list_of_queries.pretty_inspect

    unless (@list_of_queries.empty?)

      @list_of_queries.push([:data_file, associated_with, :sample])
      # do query
      q = @repository.query.select.where(*@list_of_queries).from(@graph)
      @results = @repository.select(q).collect { |result| result[:data_file] }

      @results = @results.select { |result| result.is_a?(RDF::URI) }.collect { |result| result.to_s }.uniq

      @results = get_active_records_from_urls(@results)

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
