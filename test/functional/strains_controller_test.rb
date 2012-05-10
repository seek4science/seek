require 'test_helper'

class StrainsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:aaron)
    @object=Factory :strain
  end

  test "get existing strains with no organism" do

    xml_http_request :get,:show_existing_strains,{:organism_id=>"0"}
    assert_response :success

  end
end
