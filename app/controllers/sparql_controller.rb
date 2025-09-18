require 'sparql/client'
require 'net/http'

class SparqlController < ApplicationController
  layout 'application'

  before_action :rdf_repository_configured?

  def index
    # Main SPARQL interface page
    unless rdf_repository_available?
      flash.now[:error] = "SPARQL endpoint is configured, but not currently available."
    end

    @resource = nil
    @sparql_query = params[:sparql_query] || ""
    @format = params[:format] || "table"
    @example_queries = load_example_queries

    # If this is a POST request with a query, execute it
    if request.post? && @sparql_query.present?
      begin
        unless rdf_repository_available?
          raise "SPARQL endpoint is configured, but not currently available."
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

  def rdf_repository_available?
    begin
      Seek::Rdf::RdfRepository.instance.select('ask where {?s ?p ?o}')
    rescue RuntimeError => e
      Rails.logger.error("Error trying a simple query: #{e.message}")
      false
    end
  end
  def rdf_repository_configured?
    unless Seek::Rdf::RdfRepository.instance&.configured?
      flash[:error] = "SPARQL endpoint is not configured."
      redirect_to main_app.root_path
    end
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
