require 'test_helper'
require 'minitest/mock'

class RdfTripleStoreTest < ActionDispatch::IntegrationTest
  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    @project = FactoryBot.create(:project, title: 'Test for RDF storage')
    skip('these tests need a configured triple store setup') unless @repository.configured?
    
    @private_graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph

    @subject = @project.rdf_resource
  end

  def teardown
    unless @subject.nil?
      q = @repository.query.delete(%i[s p o]).graph(@private_graph).where(%i[s p o])
      @repository.delete(q)

      q = @repository.query.delete(%i[s p o]).graph(@public_graph).where(%i[s p o])
      @repository.delete(q)

      item_graphs.each { |graph| @repository.update("DROP SILENT GRAPH #{graph.to_base}") }
      @repository.update("DROP SILENT GRAPH #{@repository.item_index_graph_uri.to_base}")

      @project.delete_rdf_file
    end
  end

  # a sanity check that the helper method, that the other tests rely on, is working correctly
  test 'triple count' do
    count = triple_count(@project)
    assert count > 0
  end

  test 'singleton repository' do
    repo = Seek::Rdf::RdfRepository.instance
    repo2 = Seek::Rdf::RdfRepository.instance
    assert repo == repo2
    assert repo.is_a?(Seek::Rdf::VirtuosoRepository)
  end

  test 'configured for send' do
    assert @repository.configured?
    assert @project.rdf_repository_configured?
  end

  test 'send to store' do
    @repository.send_rdf(@project)

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal 'Test for RDF storage', result[0][:o].value
    assert_equal 'http://www.w3.org/2001/XMLSchema#string', result[0][:o].datatype

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/created'), :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal 'http://www.w3.org/2001/XMLSchema#dateTime', result[0][:o].datatype
  end

  test 'remove public from store' do
    assert @project.can_view?(nil)
    @repository.send_rdf(@project)
    @project.save_rdf_file

    count = triple_count(@project)

    q = @repository.query.select.where([@subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count

    q = @repository.query.select.where([@subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal count, result.count

    @repository.remove_rdf(@project)
    q = @repository.query.select.where([@subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    q = @repository.query.select.where([@subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count
  end

  #check that it is removed from both the private and public store, even after its privacy has changed to private.
  test 'remove_rdf removes from both stores even after privacy change' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy), creators: [FactoryBot.create(:person)])
    assert sop.can_view?(nil)
    refute_empty sop.creators

    @repository.send_rdf(sop)
    subject = sop.rdf_resource

    count = triple_count(sop)

    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal count, result.count

    sop.policy.access_type = Policy::NO_ACCESS
    sop.policy.save!
    sop = Sop.find(sop.id)
    refute sop.can_view?(nil)

    @repository.remove_rdf(sop)
    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    sop.delete_rdf_file
  end

  # check that it is removed from the private store when asked to be removed
  test 'remove_rdf removes from private store' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy))
    refute sop.can_view?(nil)

    @repository.send_rdf(sop)
    subject = sop.rdf_resource

    count = triple_count(sop)

    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    @repository.remove_rdf(sop)
    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    sop.delete_rdf_file
  end

  test 'remove all even after a change' do
    @repository.send_rdf(@project)

    @project.title = 'new title'
    disable_authorization_checks { @project.save! }

    @repository.remove_rdf(@project)
    q = @repository.query.select.where([@subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 0, result.count
  end

  test 'uris of items related to' do
    person = FactoryBot.create(:person)
    data_file = FactoryBot.create(:data_file)
    model = FactoryBot.create(:model)
    sop = FactoryBot.create(:sop)

    q = @repository.query.insert([person.rdf_resource, RDF::URI.new('http://is/member_of'), @project.rdf_resource]).graph(@private_graph)
    @repository.insert(q)

    q = @repository.query.insert([data_file.rdf_resource, RDF::URI.new('http://is/created_by'), @project.rdf_resource]).graph(@private_graph)
    @repository.insert(q)

    q = @repository.query.insert([data_file.rdf_resource, RDF::URI.new('http://is/linked_to'), @project.rdf_resource]).graph(@private_graph)
    @repository.insert(q)

    q = @repository.query.insert([model.rdf_resource, RDF::URI.new('http://is/related_to'), person.rdf_resource]).graph(@private_graph)
    @repository.insert(q)

    q = @repository.query.insert([model.rdf_resource, RDF::URI.new('http://has/name'), 'A model']).graph(@private_graph)
    @repository.insert(q)

    q = @repository.query.insert([@project.rdf_resource, RDF::URI.new('http://produced'), sop.rdf_resource]).graph(@private_graph)
    @repository.insert(q)

    uris = @repository.uris_of_items_related_to @project
    assert_equal 3, uris.count
    assert_equal ["http://localhost:3000/data_files/#{data_file.id}", "http://localhost:3000/people/#{person.id}", "http://localhost:3000/sops/#{sop.id}"], uris.sort
  end

  test 'uris of items related to with only a public graph' do
    config = @repository.get_configuration.dup
    config.private_graph = nil
    person = FactoryBot.create(:person)
    sop = FactoryBot.create(:sop)

    q = @repository.query.insert([person.rdf_resource, RDF::URI.new('http://is/member_of'), @project.rdf_resource]).graph(@public_graph)
    @repository.insert(q)
    q = @repository.query.insert([@project.rdf_resource, RDF::URI.new('http://produced'), sop.rdf_resource]).graph(@public_graph)
    @repository.insert(q)

    @repository.stub(:get_configuration, config) do
      uris = @repository.uris_of_items_related_to @project
      assert_equal ["http://localhost:3000/people/#{person.id}", "http://localhost:3000/sops/#{sop.id}"], uris.sort
    end
  end

  test 'uris of items related to leave out skolemized blank nodes' do
    data_file = data_file_with_nested_extended_metadata('2020-01-01')
    @repository.send_rdf(data_file)
    assert_equal 1, nested_start_dates(data_file, @private_graph).count

    uris = @repository.uris_of_items_related_to(data_file)
    assert uris.any?, 'the data file should be related to other items'
    assert_empty uris.select { |uri| uri.include?('/.well-known/genid/') }

    assert_nothing_raised { data_file.related_items_from_sparql }

    data_file.delete_rdf_file
  end

  test 'timeout defaults to 60 seconds' do
    assert_equal 60, @repository.get_configuration.timeout
  end

  test 'update rdf' do
    @repository.send_rdf(@project)

    title = @project.title

    triple_count = triple_count(@project)

    q = @repository.query.select.where([@subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal triple_count, result.count, 'there should be 5 statements in total'

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one title statement'
    assert_equal title, result[0][:o].value

    @project.title = 'The best project ever'
    disable_authorization_checks { @project.save! }

    @repository.update_rdf(@project)

    q = @repository.query.select.where([@subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal triple_count, result.count, "there should be #{triple_count} statements in total"

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one title statement'
    assert_equal 'The best project ever', result[0][:o].value

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/modified'), :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one modified statement'
  end

  test 'update rdf change visibility' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    assert sop.can_view?(nil)

    count = triple_count(sop)

    @repository.send_rdf(sop)
    @repository.update_rdf(sop)

    subject = sop.rdf_resource

    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count, "there should be #{count} statements in total"

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal count, result.count, "there should be #{count} statements in total"

    sop.policy.access_type = Policy::NO_ACCESS
    sop.policy.save!
    sop = Sop.find(sop.id)
    refute sop.can_view?(nil), 'the sop should now be hidden'

    @repository.update_rdf(sop)

    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count, "there should be #{count} statements in total"

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count, 'there should be 0 statements in the public graph'

    disable_authorization_checks do
      sop.policy.access_type = Policy::VISIBLE
      sop.title = 'Updated Title'
      sop.save!
    end

    sop = Sop.find(sop.id)
    assert sop.can_view?(nil), 'The sop should now be visible'

    count = triple_count(sop)

    @repository.update_rdf(sop)

    q = @repository.query.select.where([subject, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count, "there should be #{count} statements in total"

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal count, result.count, "there should be #{count} statements in the public graph"

    q = @repository.query.select.where([subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal 'Updated Title', result[0][:o].value

    sop.delete_rdf_file
  end

  #checks the the rdf resource type is updated, and there is not a duplicate. This is in particular for when data changes
  # to simulation data
  test 'update rdf after resource type change' do
    data_file = FactoryBot.create(:data_file)
    refute data_file.simulation_data?

    @repository.send_rdf(data_file)

    count = triple_count(data_file)
    rdf_resource = data_file.rdf_resource

    # check the count, and the type
    q = @repository.query.select.where([data_file.rdf_resource, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count
    q = @repository.query.select.where([data_file.rdf_resource, RDF.type, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal Seek::Rdf::JERMVocab.Data, result[0][:o].value

    disable_authorization_checks do
      data_file.simulation_data=true
      data_file.save!
      data_file.reload
    end

    @repository.update_rdf(data_file)

    # now check the count is the same, and the type has been updated
    assert_equal count,triple_count(data_file)
    assert_equal rdf_resource,data_file.rdf_resource
    q = @repository.query.select.where([data_file.rdf_resource, :p, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal count, result.count
    q = @repository.query.select.where([data_file.rdf_resource, RDF.type, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal Seek::Rdf::JERMVocab.Simulation_data, result[0][:o].value

  end

  test 'send stores the statements in the item graph and records the graphs it is part of' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    @repository.send_rdf(sop)

    item_graph = @repository.item_graph_uri(sop)
    assert_equal RDF::URI("#{@private_graph}/items/Sop/#{sop.id}"), item_graph
    q = @repository.query.select.where([sop.rdf_resource, :p, :o]).from(item_graph)
    assert_equal triple_count(sop), @repository.select(q).count

    assert_equal [@private_graph, @public_graph].map(&:to_s).sort, part_of(sop).map(&:to_s).sort

    sop.policy.update!(access_type: Policy::NO_ACCESS)
    sop = Sop.find(sop.id)
    @repository.update_rdf(sop)
    assert_equal [@private_graph.to_s], part_of(sop).map(&:to_s)

    @repository.remove_rdf(sop)
    assert_empty part_of(sop)
    assert_equal 0, graph_count(item_graph)

    sop.delete_rdf_file
  end

  test 'nested extended metadata stays connected to the item' do
    data_file = data_file_with_nested_extended_metadata('2020-01-01')
    @repository.send_rdf(data_file)

    [@private_graph, @public_graph].each do |graph|
      assert_equal ['2020-01-01'], nested_start_dates(data_file, graph)
    end

    data_file.delete_rdf_file
  end

  test 'nested extended metadata is replaced on update and removed' do
    data_file = data_file_with_nested_extended_metadata('2020-01-01')
    @repository.send_rdf(data_file)
    count = graph_count(@private_graph)

    disable_authorization_checks do
      data_file.extended_metadata.set_attribute_value('retention_period',
                                                      { 'start_date' => '2021-06-01', 'end_date' => '2030-12-31' })
      data_file.extended_metadata.save!
    end
    @repository.update_rdf(data_file)
    @repository.update_rdf(data_file)

    assert_equal count, graph_count(@private_graph)
    assert_equal ['2021-06-01'], nested_start_dates(data_file, @private_graph)

    @repository.remove_rdf(data_file)
    assert_equal 0, graph_count(@private_graph)
    assert_equal 0, graph_count(@public_graph)
  end

  test 'remove keeps statements that another item also sent' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    shared = [RDF::URI('http://example.org/shared'), RDF::URI('http://example.org/p'), RDF::URI('http://example.org/o')]
    sop.define_singleton_method(:to_rdf_graph) { super() << shared }
    @project.define_singleton_method(:to_rdf_graph) { super() << shared }

    @repository.send_rdf(sop)
    @repository.send_rdf(@project)
    @repository.remove_rdf(sop)

    [@private_graph, @public_graph].each do |graph|
      q = @repository.query.select.where(shared).from(graph)
      assert_equal 1, @repository.select(q).count, "the shared statement should remain in #{graph}"
      q = @repository.query.select.where([sop.rdf_resource, :p, :o]).from(graph)
      assert_equal 0, @repository.select(q).count
    end

    @repository.remove_rdf(@project)
    [@private_graph, @public_graph].each do |graph|
      assert_equal 0, graph_count(graph)
    end
  end

  test 'only a public graph configured' do
    config = @repository.get_configuration.dup
    config.private_graph = nil
    public_sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    private_sop = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy))

    @repository.stub(:get_configuration, config) do
      assert_equal RDF::URI("#{@public_graph}/items/Sop/#{public_sop.id}"), @repository.item_graph_uri(public_sop)

      @repository.send_rdf(public_sop)
      @repository.send_rdf(private_sop)

      q = @repository.query.select.where([public_sop.rdf_resource, :p, :o]).from(@public_graph)
      assert_equal triple_count(public_sop), @repository.select(q).count
      assert_equal [@public_graph.to_s], part_of(public_sop).map(&:to_s)

      q = @repository.query.select.where([private_sop.rdf_resource, :p, :o]).from(@public_graph)
      assert_equal 0, @repository.select(q).count
      assert_equal 0, graph_count(@repository.item_graph_uri(private_sop)), 'a private item should not be stored'
      assert_empty part_of(private_sop)

      public_sop.policy.update!(access_type: Policy::NO_ACCESS)
      public_sop = Sop.find(public_sop.id)
      @repository.update_rdf(public_sop)

      assert_equal 0, graph_count(@public_graph)
      assert_equal 0, graph_count(@repository.item_graph_uri(public_sop))
      assert_empty part_of(public_sop)
    end

    public_sop.delete_rdf_file
    private_sop.delete_rdf_file
  end

  private

  def data_file_with_nested_extended_metadata(start_date)
    em = ExtendedMetadata.new(extended_metadata_type: FactoryBot.create(:rdf_test_data_file_single_nested_emt))
    em.set_attribute_value('retention_period', { 'start_date' => start_date, 'end_date' => '2030-12-31' })
    FactoryBot.create(:data_file, extended_metadata: em, policy: FactoryBot.create(:public_policy))
  end

  # the start dates reached by following the item's retention period link, in the given graph
  def nested_start_dates(data_file, graph)
    results = @repository.select(<<~SPARQL)
      SELECT ?date FROM #{graph.to_base} WHERE {
        #{data_file.rdf_resource.to_base} <http://example.org/retentionPeriod> ?period .
        ?period <http://example.org/startDate> ?date
      }
    SPARQL
    results.map { |result| result[:date].to_s }
  end

  def graph_count(graph)
    q = @repository.query.select.where(%i[s p o]).from(RDF::URI(graph))
    @repository.select(q).count
  end

  def part_of(item)
    q = @repository.query.select
                   .where([@repository.item_graph_uri(item), RDF::Vocab::DC.isPartOf, :g])
                   .from(@repository.item_index_graph_uri)
    @repository.select(q).map { |result| result[:g] }
  end

  def item_graphs
    q = @repository.query.select.distinct.where([:g, RDF::Vocab::DC.isPartOf, :o]).from(@repository.item_index_graph_uri)
    @repository.select(q).map { |result| result[:g] }
  end

  # gets the count of the triples for a resource. This can change as the rdf is updated, so avoids having hard-coded
  # variables making the tests fragile
  def triple_count(object)
    rdf = object.to_rdf
    RDF::Reader.for(:ttl).new(rdf).statements.count
  end
end
