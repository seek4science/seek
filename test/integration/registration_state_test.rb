require 'test_helper'

class RegistrationStateTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper
  fixtures :all

  test 'partially registered user always redirects to select person' do
    User.current_user = Factory(:user, login: 'partial', person: nil)
    post '/session', login: 'partial', password: 'blah'
    assert_redirected_to register_people_path

    assert_nil User.current_user.person

    get register_people_path
    assert_response :success

    get new_session_path
    assert_response :success

    get people_path
    assert_redirected_to register_people_path

    get models_path
    assert_redirected_to register_people_path

    get root_path
    assert_redirected_to register_people_path

    get sop_path(Factory :sop)
    assert_redirected_to register_people_path
  end
end
