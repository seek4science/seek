require 'test_helper'

class RdfTripleStoreTest < ActionController::IntegrationTest

    def setup
      @project = Factory(:project,:title=>"Test for RDF storage")
      skip("these tests need a configured triple store setup") unless @project.configured_for_rdf_send?
      WebMock.allow_net_connect!
      @graph = RDF::URI.new("seek-tests:private")

      @subject = @project.rdf_resource
    end

    def teardown
      unless @subject.nil?
        query = @project.get_query_object
        repo = @project.get_repository
        q = query.delete([@subject, :p, :o]).graph(@graph).where([@subject, :p, :o])
        result = repo.delete(q)
      end
    end

    test "configured for send" do
      assert @project.configured_for_rdf_send?
    end

    test "send to store" do
      @project.send_rdf_to_repository
      query = @project.get_query_object
      repo = @project.get_repository
      q = query.select.where([@subject, RDF::URI.new("http://purl.org/dc/terms/title"), :o]).from(@graph)
      result = repo.select(q)
      assert_equal 1,result.count
      assert_equal "Test for RDF storage",result[0][:o].value
    end

    test "remove from store" do
      @project.send_rdf_to_repository
      @project.save_rdf

      query = @project.get_query_object
      repo = @project.get_repository

      q = query.select.where([@subject, :p, :o]).from(@graph)
      result = repo.select(q)
      assert_equal 5,result.count

      @project.remove_rdf_from_repository
      q = query.select.where([@subject, :p, :o]).from(@graph)
      result = repo.select(q)
      assert_equal 0,result.count
    end


end