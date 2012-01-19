require 'test_helper'

class StrainsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:aaron)
    @object=strains(:yeast1)
  end

  test "get existing strains with no organism" do

    xml_http_request :get,:show_existing_strains,{:organism_id=>"0"}
    assert_response :success

  end

  test 'should create strain with name and organism' do
    @request.env["HTTP_REFERER"]  = ''
    organism = organisms(:yeast)
    strain = {:title => 'test', :organism => organism}
    assert_difference ('Strain.count') do
      post :create, :strain => strain
    end
  end

  test 'should not be able to create strain without login' do
    logout
    @request.env["HTTP_REFERER"]  = ''
    organism = organisms(:yeast)
    strain = {:title => 'test', :organism => organism}
    assert_no_difference ('Strain.count') do
      post :create, :strain => strain
    end
    assert_not_nil flash[:error]
  end

end
