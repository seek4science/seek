require 'test_helper'

class RdfTripleStoreTest < ActionController::IntegrationTest

    def setup
      @project = Factory(:project)
      skip("these tests need a configured triple store setup") unless @project.configured_for_rdf_send?
      WebMock.allow_net_connect!
    end

    test "configured for send" do
      assert @project.configured_for_rdf_send?
    end

    test "send to store" do
      @project.send_rdf_to_repository
    end


end