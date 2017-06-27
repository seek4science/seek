require 'test_helper'

class RdfTripleStoreTest < ActionDispatch::IntegrationTest
  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    @project = Factory(:project, title: 'Test for RDF storage')
    skip('these tests need a configured triple store setup') unless @repository.configured?
    WebMock.allow_net_connect!
    @graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph

    @subject = @project.rdf_resource
  end

  def teardown
    unless @subject.nil?
      q = @repository.query.delete([:s, :p, :o]).graph(@graph).where([:s, :p, :o])
      @repository.delete(q)

      q = @repository.query.delete([:s, :p, :o]).graph(@public_graph).where([:s, :p, :o])
      @repository.delete(q)

      @project.delete_rdf_file
    end
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

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal 'Test for RDF storage', result[0][:o].value
  end

  test 'remove public from store' do
    assert @project.can_view?(nil)
    @repository.send_rdf(@project)
    @project.save_rdf_file

    q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 5, result.count

    q = @repository.query.select.where([@subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 5, result.count

    @repository.remove_rdf(@project)
    q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    q = @repository.query.select.where([@subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count
  end

  test 'remove from store after privacy change' do
    sop = Factory(:sop, policy: Factory(:public_policy))
    assert sop.can_view?(nil)

    @repository.send_rdf(sop)
    subject = sop.rdf_resource

    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 9, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 9, result.count

    sop.policy.access_type = Policy::NO_ACCESS
    sop.policy.save!
    sop = Sop.find(sop.id)
    assert !sop.can_view?(nil)

    @repository.remove_rdf(sop)
    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    sop.delete_rdf_file
  end

  test 'remove private from store' do
    sop = Factory(:sop, policy: Factory(:private_policy))
    assert !sop.can_view?(nil)

    @repository.send_rdf(sop)
    subject = sop.rdf_resource

    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 9, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    @repository.remove_rdf(sop)
    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 0, result.count

    sop.delete_rdf_file
  end

  test 'remove even after a change' do
    @repository.send_rdf(@project)

    @project.title = 'new title'
    @project.save!

    @repository.remove_rdf(@project)
    q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 0, result.count
  end

  test 'uris of items related to' do
    person = Factory(:person)
    data_file = Factory(:data_file)
    model = Factory(:model)
    sop = Factory(:sop)

    q = @repository.query.insert([person.rdf_resource, RDF::URI.new('http://is/member_of'), @project.rdf_resource]).graph(@graph)
    @repository.insert(q)

    q = @repository.query.insert([data_file.rdf_resource, RDF::URI.new('http://is/created_by'), @project.rdf_resource]).graph(@graph)
    @repository.insert(q)

    q = @repository.query.insert([data_file.rdf_resource, RDF::URI.new('http://is/linked_to'), @project.rdf_resource]).graph(@graph)
    @repository.insert(q)

    q = @repository.query.insert([model.rdf_resource, RDF::URI.new('http://is/related_to'), person.rdf_resource]).graph(@graph)
    @repository.insert(q)

    q = @repository.query.insert([model.rdf_resource, RDF::URI.new('http://has/name'), 'A model']).graph(@graph)
    @repository.insert(q)

    q = @repository.query.insert([@project.rdf_resource, RDF::URI.new('http://produced'), sop.rdf_resource]).graph(@graph)
    @repository.insert(q)

    uris = @repository.uris_of_items_related_to @project
    assert_equal 3, uris.count
    assert_equal ["http://localhost:3000/data_files/#{data_file.id}", "http://localhost:3000/people/#{person.id}", "http://localhost:3000/sops/#{sop.id}"], uris.sort
  end

  test 'update rdf' do
    @repository.send_rdf(@project)

    title = @project.title

    q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 5, result.count, 'there should be 5 statements in total'

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one title statement'
    assert_equal title, result[0][:o].value

    @project.title = 'The best project ever'
    @project.save!

    @repository.update_rdf(@project)

    q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 5, result.count, 'there should be 5 statements in total'

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one title statement'
    assert_equal 'The best project ever', result[0][:o].value

    q = @repository.query.select.where([@subject, RDF::URI.new('http://purl.org/dc/terms/modified'), :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 1, result.count, 'there should only be one modified statement'
  end

  test 'update rdf change visibility' do
    sop = Factory(:sop, policy: Factory(:public_policy))
    assert sop.can_view?(nil)

    @repository.update_rdf(sop)

    subject = sop.rdf_resource

    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 9, result.count, 'there should be 9 statements in total'

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 9, result.count, 'there should be 9 statements in total'

    sop.policy.access_type = Policy::NO_ACCESS
    sop.policy.save!
    sop = Sop.find(sop.id)
    assert !sop.can_view?(nil), 'the sop should now be hidden'

    @repository.update_rdf(sop)

    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 9, result.count, 'there should be 9 statements in total'

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

    @repository.update_rdf(sop)

    q = @repository.query.select.where([subject, :p, :o]).from(@graph)
    result = @repository.select(q)
    assert_equal 9, result.count, 'there should be 9 statements in total'

    q = @repository.query.select.where([subject, :p, :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 9, result.count, 'there should be 9 statements in the public graph'

    q = @repository.query.select.where([subject, RDF::URI.new('http://purl.org/dc/terms/title'), :o]).from(@public_graph)
    result = @repository.select(q)
    assert_equal 1, result.count
    assert_equal 'Updated Title', result[0][:o].value

    sop.delete_rdf_file
  end
end
