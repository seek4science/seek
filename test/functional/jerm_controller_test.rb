require 'test_helper'

class JermControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  fixtures :all

  test 'index' do
    with_config_value :jerm_enabled, true do
      login_as(:quentin)
      get :index
      assert_response :success
    end
  end

  test 'no index for non-admin' do
    with_config_value :jerm_enabled, true do
      login_as(:aaron)
      get :index
      assert_redirected_to :root
    end
  end
end
