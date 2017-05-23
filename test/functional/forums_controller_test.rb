require 'test_helper'

class ForumsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  setup do
    skip('Skipping forums tests for now')
  end

  def test_login_required_for_index
    get :index
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_index
    login_as(:quentin)
    get :index
    assert_response :success
  end
end
