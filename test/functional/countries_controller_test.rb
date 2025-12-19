require 'test_helper'

class CountriesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as :quentin
  end

  test 'get country' do
    get :show, params: { country_code: 'GB' }
    assert_response :success
    assert_select 'h1',text:/United Kingdom/

    get :show, params: { country_code: 'gb' }
    assert_response :success
    assert_select 'h1',text:/United Kingdom/

    get :show, params: { country_code: 'Netherlands' }
    assert_response :success
    assert_select 'h1',text:/Netherlands/

    get :show, params: { country_code: 'GERMANY' }
    assert_response :success
    assert_select 'h1',text:/Germany/

    #invalid
    get :show, params: { country_code: 'zz' }
    assert_response :not_found

    #invalid
    get :show, params: { country_code: 'land of oz' }
    assert_response :not_found


  end
end
