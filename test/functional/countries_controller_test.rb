require 'test_helper'

class CountriesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as :quentin
  end

  test 'get Netherlands' do
    get :show, country_name: 'Netherlands'
    assert_response :success
  end
end
