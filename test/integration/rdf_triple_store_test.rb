require 'test_helper'

class RdfTripleStoreTest < ActionController::IntegrationTest

    def setup
      @project = Factory(:project)
      skip unless @project.configured_for_rdf_send?
      WebMock.allow_net_connect!
    end

    test "configured for send" do
      sop = Factory(:project)
      assert sop.configured_for_rdf_send?
    end

    test "send to store" do
      sop = Factory(:project)
      sop.send_rdf_to_repository
    end


end