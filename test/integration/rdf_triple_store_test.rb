require 'test_helper'

class RdfTripleStoreTest < ActionDispatch::IntegrationTest

  include MockHelper
  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    @project = FactoryBot.create(:max_project, title: 'Test for RDF storage')
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

      @repository.delete(<<~SPARQL)
        DELETE { GRAPH ?g { ?s ?p ?o } }
        WHERE { GRAPH ?g { ?s ?p ?o } FILTER(STRSTARTS(STR(?g), "#{@private_graph}/items/")) }
      SPARQL

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

  test 'send schema to store' do
    ror_mock
    wf = FactoryBot.create(:max_workflow, projects: [@project], title: 'RDF test workflow')
    df = FactoryBot.create(:data_file, projects: [@project], title: 'RDF test data file')
    @project.reload
    @repository.send_rdf(wf)

    # @repository.send_rdf(@project)
    @repository.send_rdf(df)
    person = FactoryBot.create(:max_person, first_name: 'RDF', last_name: 'Tester')
    pp person.to_rdf
    @repository.send_rdf(person)

    inst = FactoryBot.create(:max_institution, title: 'RDF test institution', projects: [@project])
    pp inst.to_rdf_graph
    @repository.send_rdf(inst)
  end

  test 'update rdf for a workflow replaces the bioschemas and ro-crate statements' do
    workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy), title: 'Original title')
    crate = RDF::URI("#{workflow.rdf_seek_id}/crate/")
    main_file = RDF::URI("#{workflow.rdf_seek_id}/crate/workflow.cwl")
    name = RDF::URI('https://schema.org/name')

    # generating the RO-Crate creates the workflow diagram, which then adds a schema:image statement, so generate
    # it once first to keep the statement count stable
    workflow.to_rdf
    @repository.send_rdf(workflow)
    count = triple_count(workflow)
    assert_equal count, count_in_graph(workflow, @private_graph)
    assert_equal count, count_in_graph(workflow, @public_graph)
    assert_equal ['Original title'], values_of(workflow.rdf_resource, name, @public_graph)
    assert_equal ['Original title'], values_of(main_file, name, @public_graph)
    assert_equal ['Research Object Crate for Original title'], values_of(crate, name, @public_graph)

    disable_authorization_checks { workflow.update!(title: 'Updated title') }
    workflow = Workflow.find(workflow.id)
    @repository.update_rdf(workflow)

    assert_equal triple_count(workflow), count_in_graph(workflow, @private_graph)
    [@private_graph, @public_graph].each do |graph|
      assert_equal ['Updated title'], values_of(workflow.rdf_resource, name, graph)
      assert_equal ['Updated title'], values_of(main_file, name, graph)
      assert_equal ['Research Object Crate for Updated title'], values_of(crate, name, graph)
    end

    assert_equal 0, @repository.select(<<~SPARQL)[0][:c].object.to_i
      SELECT (COUNT(*) AS ?c) WHERE {
        GRAPH #{@private_graph.to_base} { ?s ?p ?o }
        FILTER(STRSTARTS(STR(?p), "http://schema.org/") || STRSTARTS(STR(?o), "http://schema.org/"))
      }
    SPARQL

    @repository.remove_rdf(workflow)
    assert_empty values_of(crate, name, @private_graph)
    assert_empty values_of(main_file, name, @private_graph)
  end

  test 'remove public from store' do
    assert @project.can_view?(nil)
    @repository.send_rdf(@project)
    @project.save_rdf_file

    count = triple_count(@project)

    assert_equal count, count_in_graph(@project, @private_graph)

    assert_equal count, count_in_graph(@project, @public_graph)

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

    assert_equal count, count_in_graph(sop, @private_graph)

    assert_equal count, count_in_graph(sop, @public_graph)

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

    assert_equal count, count_in_graph(sop, @private_graph)

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

  test 'update rdf' do
    @repository.send_rdf(@project)

    title = @project.title

    triple_count = triple_count(@project)

    assert_equal triple_count, count_in_graph(@project, @private_graph), 'there should be 5 statements in total'

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one title statement'
    assert_equal title, result[0][:o].value

    @project.title = 'The best project ever'
    disable_authorization_checks { @project.save! }

    @repository.update_rdf(@project)

    assert_equal triple_count, count_in_graph(@project, @private_graph), "there should be #{triple_count} statements in total"

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

    assert_equal count, count_in_graph(sop, @private_graph), "there should be #{count} statements in total"

    assert_equal count, count_in_graph(sop, @public_graph), "there should be #{count} statements in total"

    sop.policy.access_type = Policy::NO_ACCESS
    sop.policy.save!
    sop = Sop.find(sop.id)
    refute sop.can_view?(nil), 'the sop should now be hidden'

    @repository.update_rdf(sop)

    assert_equal count, count_in_graph(sop, @private_graph), "there should be #{count} statements in total"

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

    assert_equal count, count_in_graph(sop, @private_graph), "there should be #{count} statements in total"

    assert_equal count, count_in_graph(sop, @public_graph), "there should be #{count} statements in the public graph"

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
    assert_equal count, count_in_graph(data_file, @private_graph)
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
    assert_equal count, count_in_graph(data_file, @private_graph)
    q = @repository.query.select.where([data_file.rdf_resource, RDF.type, :o]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal Seek::Rdf::JERMVocab.Simulation_data, result[0][:o].value

  end

  test 'send rdf records the item contribution in its own named graph' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    @repository.send_rdf(sop)
    item_graph = @repository.item_graph_uri(sop)

    assert_equal triple_count(sop), item_triple_count(sop)
    assert_equal triple_count(sop), count_in_graph(sop, @private_graph)
    assert_equal triple_count(sop), count_in_graph(sop, @public_graph)

    q = @repository.query.select.where([item_graph, RDF::Vocab::DC.isPartOf, :g]).from(item_graph)
    assert_equal [@private_graph.to_s, @public_graph.to_s].sort, @repository.select(q).map { |r| r[:g].to_s }.sort

    sop.delete_rdf_file
  end

  test 'update rdf removes stale statements about other subjects' do
    person = FactoryBot.create(:person, first_name: 'Old', last_name: 'Name')
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy), creators: [person])
    @repository.send_rdf(sop)
    assert_equal ['Old Name'], names_of(person, @private_graph)
    assert_equal ['Old Name'], names_of(person, @public_graph)

    disable_authorization_checks { person.update!(first_name: 'New') }
    @repository.update_rdf(Sop.find(sop.id))

    assert_equal ['New Name'], names_of(person, @private_graph)
    assert_equal ['New Name'], names_of(person, @public_graph)

    sop.delete_rdf_file
  end

  test 'remove rdf keeps statements still asserted by another item' do
    person = FactoryBot.create(:person, first_name: 'Shared', last_name: 'Creator')
    sop1 = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy), creators: [person])
    sop2 = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy), creators: [person])
    @repository.send_rdf(sop1)
    @repository.send_rdf(sop2)

    @repository.remove_rdf(sop1)
    assert_equal 0, item_triple_count(sop1)
    assert_equal ['Shared Creator'], names_of(person, @private_graph)
    assert_equal ['Shared Creator'], names_of(person, @public_graph)
    q = @repository.query.select.where([sop1.rdf_resource, :p, :o]).from(@private_graph)
    assert_empty @repository.select(q)

    @repository.remove_rdf(sop2)
    assert_empty names_of(person, @private_graph)
    assert_empty names_of(person, @public_graph)
  end

  test 'remove rdf from public graph ignores statements only asserted by private items' do
    person = FactoryBot.create(:person, first_name: 'Mixed', last_name: 'Visibility')
    public_sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy), creators: [person])
    private_sop = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy), creators: [person])
    @repository.send_rdf(public_sop)
    @repository.send_rdf(private_sop)

    @repository.remove_rdf(public_sop)
    assert_empty names_of(person, @public_graph)
    assert_equal ['Mixed Visibility'], names_of(person, @private_graph)

    private_sop.delete_rdf_file
  end

  test 'blank nodes are skolemized and do not accumulate' do
    data_file = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
    distribution = RDF::URI('https://schema.org/distribution')

    @repository.send_rdf(data_file)
    @repository.update_rdf(data_file)
    @repository.update_rdf(data_file)

    q = @repository.query.select.where([data_file.rdf_resource, distribution, :d]).from(@private_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    skolem = result[0][:d]
    assert skolem.uri?
    assert skolem.to_s.start_with?(Seek::Config.site_base_url.join('.well-known/genid/').to_s)

    q = @repository.query.select.where([skolem, :p, :o]).from(@private_graph)
    refute_empty @repository.select(q)
    assert_equal triple_count(data_file), count_in_graph(data_file, @private_graph)
    assert_equal 1, @repository.select(<<~SPARQL)[0][:c].object.to_i
      SELECT (COUNT(DISTINCT ?d) AS ?c) WHERE {
        GRAPH #{@private_graph.to_base} { ?d a <https://schema.org/DataDownload> }
        FILTER(STRSTARTS(STR(?d), "#{Seek::Config.site_base_url.join('.well-known/genid/')}"))
      }
    SPARQL

    @repository.remove_rdf(data_file)
    q = @repository.query.select.where([skolem, :p, :o]).from(@private_graph)
    assert_empty @repository.select(q)
  end

  private

  # gets the count of the triples for a resource. This can change as the rdf is updated, so avoids having hard-coded
  # variables making the tests fragile
  def triple_count(object)
    rdf = object.to_rdf
    RDF::Reader.for(:ttl).new(rdf).statements.count
  end

  # the number of statements in the item's named graph, excluding the record of which graphs it is part of
  def item_triple_count(item)
    item_graph = @repository.item_graph_uri(item)
    @repository.select(<<~SPARQL)[0][:c].object.to_i
      SELECT (COUNT(*) AS ?c) WHERE {
        GRAPH #{item_graph.to_base} { ?s ?p ?o }
        FILTER(?p != #{RDF::Vocab::DC.isPartOf.to_base})
      }
    SPARQL
  end

  # the number of the item's statements that are present in graph
  def count_in_graph(item, graph)
    item_graph = @repository.item_graph_uri(item)
    @repository.select(<<~SPARQL)[0][:c].object.to_i
      SELECT (COUNT(*) AS ?c) WHERE {
        GRAPH #{item_graph.to_base} { ?s ?p ?o }
        GRAPH #{RDF::URI(graph).to_base} { ?s ?p ?o }
      }
    SPARQL
  end

  def names_of(item, graph)
    values_of(item.rdf_resource, RDF::URI('https://schema.org/name'), graph)
  end

  def values_of(subject, predicate, graph)
    q = @repository.query.select.where([subject, predicate, :value]).from(graph)
    @repository.select(q).map { |r| r[:value].to_s }
  end
end
