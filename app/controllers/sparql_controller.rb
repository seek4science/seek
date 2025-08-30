require 'sparql/client'
require 'net/http'

class SparqlController < ApplicationController
  layout 'application'

  # before_action :login_required

  def index
    # Main SPARQL interface page
    unless rdf_repository_configured?
      flash.now[:error] = "SPARQL endpoint is not configured. Please check your RDF repository configuration."
    end

    @resource = nil
    @sparql_query = params[:sparql_query] || ""
    @format = params[:format] || "table"
    @example_queries = load_example_queries

    # If this is a POST request with a query, execute it
    if request.post? && @sparql_query.present?
      begin
        unless rdf_repository_configured?
          raise "SPARQL endpoint not configured. Please configure your RDF repository settings."
        end

        @results = execute_sparql_query(@sparql_query)
        @result_count = @results.length
      rescue => e
        @error = e.message
        Rails.logger.error("SPARQL Query Error: #{e.message}")
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: @results || [] }
      format.xml { render xml: (@results || []).to_xml }
      format.any { render :index }
    end
  end

  def query
    @sparql_query = params[:sparql_query]
    @format = params[:format] || 'table'
    @resource = nil
    @example_queries = load_example_queries

    if @sparql_query.present?
      begin
        unless rdf_repository_configured?
          raise "SPARQL endpoint not configured. Please configure your RDF repository settings."
        end

        @results = execute_sparql_query(@sparql_query)
        @result_count = @results.length
      rescue => e
        @error = e.message
        Rails.logger.error("SPARQL Query Error: #{e.message}")
      end
    end

    # Always respond with HTML for form submissions
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @results || [] }
      format.xml { render xml: (@results || []).to_xml }
      format.any { render :index } # Fallback for any unknown format
    end
  end

  private

  def execute_sparql_query(query)
    # Use the repository object directly if configured
    if defined?(Seek::Rdf::RdfRepository) && Seek::Rdf::RdfRepository.instance.configured?
      begin
        repository = Seek::Rdf::RdfRepository.instance.get_repository_object
        if repository
          results = repository.query(query)
          return convert_sparql_results(results)
        end
      rescue => e
        Rails.logger.warn("Repository object query failed, trying direct SPARQL client: #{e.message}")
        # Fallback to direct SPARQL client without authentication
        return execute_sparql_query_direct(query)
      end
    end
    
    # If we get here, the endpoint is not properly configured
    raise "SPARQL endpoint is not configured. Please configure your RDF repository settings."
  end

  def execute_sparql_query_direct(query)
    # Direct SPARQL client approach without authentication
    if defined?(Seek::Rdf::RdfRepository) && Seek::Rdf::RdfRepository.instance.configured?
      config = Seek::Rdf::RdfRepository.instance.get_configuration
      # Use only the base SPARQL endpoint without authentication
      sparql_client = SPARQL::Client.new(config.uri)
      results = sparql_client.query(query)
      return convert_sparql_results(results)
    end
    
    raise "SPARQL endpoint is not configured."
  end

  def convert_sparql_results(results)
    return [] if results.nil?
    
    # Handle empty collections
    return [] if results.respond_to?(:empty?) && results.empty?

    # Handle different result formats
    if results.respond_to?(:map)
      results.map do |solution|
        if solution.respond_to?(:to_h)
          solution.to_h.transform_values { |v| v.respond_to?(:to_s) ? v.to_s : v }
        elsif solution.respond_to?(:bindings)
          solution.bindings.transform_values { |v| v.respond_to?(:to_s) ? v.to_s : v }
        else
          solution.to_s
        end
      end
    else
      # This handles ASK queries (boolean) and any other single values
      [{ 'result' => results.to_s }]
    end
  end

  def rdf_repository_configured?
    # Check if SEEK's RDF repository is configured
    if defined?(Seek::Rdf::RdfRepository)
      begin
        repository = Seek::Rdf::RdfRepository.instance
        if repository.configured?
          # Try to get repository object, but don't fail if it has issues
          begin
            repo_obj = repository.get_repository_object
            return repo_obj.present?
          rescue => e
            Rails.logger.warn("Repository object creation failed, trying basic connectivity test: #{e.message}")
            # Fallback: test basic connectivity
            return test_basic_sparql_connectivity(repository.get_configuration)
          end
        end
      rescue => e
        Rails.logger.error("RDF Repository check failed: #{e.message}")
        Rails.logger.error("Error backtrace: #{e.backtrace.first(5).join("\n")}")
      end
    end
    
    false
  end

  def test_basic_sparql_connectivity(config)
    # Try without authentication first (public read-only access)
    uri = URI(config.uri)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/sparql-query'
    request.body = 'ASK WHERE { ?s ?p ?o }'
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    # If successful without auth, great!
    return true if response.code.to_i < 400
    
    # If 401/403, try with authentication
    if [401, 403].include?(response.code.to_i) && config.username
      request.basic_auth(config.username, config.password)
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      return response.code.to_i < 400
    end
    
    false
  rescue => e
    Rails.logger.debug("Basic SPARQL connectivity test failed: #{e.message}")
    false
  end

  def load_example_queries
    queries_file = Rails.root.join('config', 'sparql_queries.yml')
    if File.exist?(queries_file)
      YAML.safe_load(File.read(queries_file)) || {}
    else
      {}
    end
  rescue => e
    Rails.logger.error("Failed to load SPARQL queries: #{e.message}")
    {}
  end
end
