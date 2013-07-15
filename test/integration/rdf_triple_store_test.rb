require 'test_helper'

class RdfTripleStoreTest < ActionController::IntegrationTest

    def setup
      @repository = Seek::Rdf::RdfRepository.instance
      @project = Factory(:project,:title=>"Test for RDF storage")
      skip("these tests need a configured triple store setup") unless @repository.configured?
      WebMock.allow_net_connect!
      @graph = RDF::URI.new @repository.get_configuration.private_graph

      @subject = @project.rdf_resource
    end

    def teardown
      unless @subject.nil?
        q = @repository.query.delete([@subject, :p, :o]).graph(@graph).where([@subject, :p, :o])
        @repository.delete(q)
      end
    end


    test "singleton repository" do
      repo = Seek::Rdf::RdfRepository.instance
      repo2 = Seek::Rdf::RdfRepository.instance
      assert repo==repo2
      assert repo.is_a?(Seek::Rdf::VirtuosoRepository)
    end


    test "configured for send" do
      assert @repository.configured?
    end

    test "send to store" do
      @repository.send_rdf(@project)

      q = @repository.query.select.where([@subject, RDF::URI.new("http://purl.org/dc/terms/title"), :o]).from(@graph)
      result = @repository.select(q)
      assert_equal 1,result.count
      assert_equal "Test for RDF storage",result[0][:o].value
    end

    test "remove from store" do
      @repository.send_rdf(@project)
      @project.save_rdf

      q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
      result = @repository.select(q)
      assert_equal 5,result.count

      @repository.remove_rdf(@project)
      q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
      result = @repository.select(q)
      assert_equal 0,result.count
    end

    test "remove even after a change" do
      @repository.send_rdf(@project)
      @project.save_rdf

      @project.title="new title"
      @project.save!

      @repository.remove_rdf(@project)
      q = @repository.query.select.where([@subject, :p, :o]).from(@graph)
      result = @repository.select(q)
      assert_equal 0,result.count
    end

    test "uris of items related to" do
      person = Factory(:person)
      data_file = Factory(:data_file)
      model = Factory(:model)
      sop = Factory(:sop)

      pp SEEK::Application.routes.recognize_path("http://news.bbc.co.uk")

      q = @repository.query.insert([person.rdf_resource,RDF::URI.new("http://is/member_of"),@project.rdf_resource]).graph(@graph)
      @repository.insert(q)

      q = @repository.query.insert([data_file.rdf_resource,RDF::URI.new("http://is/created_by"),@project.rdf_resource]).graph(@graph)
      @repository.insert(q)

      q = @repository.query.insert([data_file.rdf_resource,RDF::URI.new("http://is/linked_to"),@project.rdf_resource]).graph(@graph)
      @repository.insert(q)

      q = @repository.query.insert([model.rdf_resource,RDF::URI.new("http://is/related_to"),person.rdf_resource]).graph(@graph)
      @repository.insert(q)

      q = @repository.query.insert([model.rdf_resource,RDF::URI.new("http://has/name"),"A model"]).graph(@graph)
      @repository.insert(q)

      q = @repository.query.insert([@project.rdf_resource,RDF::URI.new("http://produced"),sop.rdf_resource]).graph(@graph)
      @repository.insert(q)

      uris = @repository.uris_of_items_related_to @project
      assert_equal 3,uris.count
      assert_equal ["http://localhost:3000/data_files/#{data_file.id}","http://localhost:3000/people/#{person.id}","http://localhost:3000/sops/#{sop.id}"],uris.sort


    end


end