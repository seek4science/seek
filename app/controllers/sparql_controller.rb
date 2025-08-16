
class SparqlController < ApplicationController
  layout 'application'

  before_action :login_required, if: -> { Seek::Config.respond_to?(:public_seek_enabled) && !Seek::Config.public_seek_enabled }

  def index
    # Main SPARQL interface page
    unless rdf_repository_configured?
      flash.now[:warning] = "SPARQL endpoint is not configured. Please check your virtuoso_settings.yml configuration."
    end

    @resource = nil
    @sparql_query = ""
    @format = "table"
    @example_queries = load_example_queries
  end

  def query
    @sparql_query = params[:sparql_query]
    @format = params[:format] || 'table'
    @resource = nil
    @example_queries = load_example_queries

    if @sparql_query.present?
      begin
        unless rdf_repository_configured?
          raise "SPARQL endpoint not configured. Please configure virtuoso_settings.yml"
        end

        @results = execute_sparql_query(@sparql_query)
        @result_count = @results.is_a?(Array) ? @results.length : 0
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
    # Always use direct SPARQL client (no authentication needed for queries)
    require 'sparql/client'
    
    # Get URI from RDF repository config if available, otherwise use fallback
    if defined?(Seek::Rdf::RdfRepository) && Seek::Rdf::RdfRepository.instance.configured?
      config = Seek::Rdf::RdfRepository.instance.get_configuration
      virtuoso_uri = config.uri
    else
      virtuoso_uri = get_virtuoso_uri
    end
    
    sparql_client = SPARQL::Client.new(virtuoso_uri)
    results = sparql_client.query(query)
    convert_sparql_results(results)
  end

  def convert_sparql_results(results)
    return [] if results.nil? || results.empty?

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
      [results.to_s]
    end
  end

  def rdf_repository_configured?
    # Check if SEEK's RDF repository is configured
    if defined?(Seek::Rdf::RdfRepository)
      begin
        return Seek::Rdf::RdfRepository.instance.configured?
      rescue => e
        Rails.logger.debug("RDF Repository check failed: #{e.message}")
      end
    end

    # Fallback to checking Virtuoso configuration directly
    config_file = Rails.root.join('config', 'virtuoso_settings.yml')
    return false unless File.exist?(config_file)

    begin
      config = YAML.safe_load(ERB.new(File.read(config_file)).result)
      env_config = config[Rails.env]
      return false if env_config.nil? || env_config['disabled']

      # Check if URI is present and not just the default localhost
      uri = env_config['uri']
      uri.present? && !uri.include?('localhost:8890/sparql') ||
        (uri.include?('localhost:8890/sparql') && virtuoso_available?)
    rescue
      false
    end
  end

  private

  def virtuoso_available?
    # Quick check to see if Virtuoso is actually running on localhost:8890
    begin
      require 'net/http'
      uri = URI('http://localhost:8890/sparql/')
      response = Net::HTTP.get_response(uri)
      response.code.to_i < 500  # Accept any response that's not a server error
    rescue
      false
    end
  end

  def get_virtuoso_uri
    # Try to get URI from SEEK's RDF repository first
    if defined?(Seek::Rdf::RdfRepository) && Seek::Rdf::RdfRepository.instance.configured?
      begin
        config = Seek::Rdf::RdfRepository.instance.get_configuration
        if config.respond_to?(:uri) && config.uri.present?
          uri = config.uri
          # Ensure the URI ends with a slash for SPARQL endpoint
          return uri.end_with?('/') ? uri : "#{uri}/"
        end
      rescue
        # Fall through to file-based config
      end
    end

    # Fallback to reading configuration file directly
    config_file = Rails.root.join('config', 'virtuoso_settings.yml')
    if File.exist?(config_file)
      config = YAML.safe_load(ERB.new(File.read(config_file)).result)
      env_config = config[Rails.env]
      if env_config && env_config['uri']
        uri = env_config['uri']
        # Ensure the URI ends with a slash for SPARQL endpoint
        return uri.end_with?('/') ? uri : "#{uri}/"
      end
    end

    # Default fallback with trailing slash
    'http://localhost:8890/sparql/'
  rescue
    'http://localhost:8890/sparql/'
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
