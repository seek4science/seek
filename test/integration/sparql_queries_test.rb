require 'test_helper'

class SparqlQueriesTest < ActionDispatch::IntegrationTest
  QUERIES = YAML.load_file(Rails.root.join('config', 'sparql_queries.yml')).freeze

  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    skip('these tests need a configured triple store') unless @repository.configured?

    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @programme = @project.programme

    User.current_user = @person.user

    @investigation = FactoryBot.create(:investigation, projects: [@project], contributor: @person,
                                                       policy: FactoryBot.create(:public_policy))
    @study = FactoryBot.create(:study, investigation: @investigation, contributor: @person,
                                       policy: FactoryBot.create(:public_policy))
    @assay = FactoryBot.create(:experimental_assay, study: @study, contributor: @person,
                                                    policy: FactoryBot.create(:public_policy))
    @data_file = FactoryBot.create(:data_file, projects: [@project], contributor: @person,
                                               policy: FactoryBot.create(:public_policy))
    @model = FactoryBot.create(:model, projects: [@project], contributor: @person,
                                       policy: FactoryBot.create(:public_policy))
    @sop = FactoryBot.create(:sop, projects: [@project], contributor: @person,
                                   policy: FactoryBot.create(:public_policy))
    @publication = FactoryBot.create(:publication, projects: [@project], contributor: @person,
                                                   policy: FactoryBot.create(:public_policy))
    @sample_type = FactoryBot.create(:simple_sample_type, projects: [@project], contributor: @person)
    @sample = FactoryBot.create(:sample, sample_type: @sample_type, projects: [@project],
                                         contributor: @person, policy: FactoryBot.create(:public_policy))
    @organism = FactoryBot.create(:organism)
    @strain = FactoryBot.create(:strain, organism: @organism, projects: [@project],
                                         policy: FactoryBot.create(:public_policy))

    rdf_items.each { |item| @repository.send_rdf(item) if item.rdf_supported? }
  end

  def teardown
    rdf_items.each { |item| @repository.remove_rdf(item) if item&.rdf_supported? }
  end

  def rdf_items
    [@investigation, @study, @assay, @data_file, @model, @sop,
     @publication, @sample, @organism, @strain, @person, @project, @programme].compact
  end

  # Dynamically generate a test for each query in sparql_queries.yml.
  # Each query must execute without error AND return at least one result,
  # ensuring the example seed data is properly reflected in the triple store.
  QUERIES.each do |key, config|
    define_method("test_query_#{key}_returns_results") do
      results = run_query(config['query'])
      assert results.any?, "Query '#{key}' (#{config['title']}) returned no results — check seed data and RDF propagation"
    end
  end

  private

  def run_query(sparql)
    client = SPARQL::Client.new(@repository.get_configuration.uri,
                                default_graph: @repository.get_configuration.private_graph)
    client.query(sparql)
  end
end
