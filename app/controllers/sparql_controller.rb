require 'sparql/client'
require 'net/http'

class SparqlController < ApplicationController
  layout 'application'

  before_action :rdf_repository_configured?

  def index
    # Main SPARQL interface page
    flash.now[:error] = 'SPARQL endpoint is configured, but not currently available.' unless rdf_repository_available?

    @example_queries = load_example_queries

    respond_to(&:html)
  end

  def query
    @sparql_query = params[:sparql_query] || ''

    if rdf_repository_available?
      begin
        @results = execute_sparql_query(@sparql_query)
      rescue StandardError => e
        @error = e.message
        Rails.logger.error("SPARQL Query Error: #{e.message}")
      end
    else
      @error = 'SPARQL endpoint is configured, but not currently available.'
      flash[:error] = @error
    end

    status = @error ? :unprocessable_entity : nil # can't use :success but is the default if nil
    @results ||= []

    respond_to do |format|
      format.html do
        @example_queries = load_example_queries
        render :index, status: status
      end
      format.json { render json: { 'results': @results, 'error': @error }.compact, status: status }
      format.xml { render xml: @results.to_xml, status: status }
    end
  end

  private

  def execute_sparql_query(query)
    sparql_client = SPARQL::Client.new(Seek::Rdf::RdfRepository.instance.get_configuration.uri)
    results = sparql_client.query(query)
    convert_sparql_results(results)
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
    Seek::Rdf::RdfRepository.instance.available?
  end

  def rdf_repository_configured?
    unless Seek::Rdf::RdfRepository.instance&.configured?
      flash[:error] = 'SPARQL endpoint is not configured.'
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
  rescue StandardError => e
    Rails.logger.error("Failed to load SPARQL queries: #{e.message}")
    {}
  end
end
