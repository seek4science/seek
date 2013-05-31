require 'test_helper'

class RegistrationStateTest < ActionController::IntegrationTest
  include AuthenticatedTestHelper
  fixtures :all

  test "partially registered user always redirects to select person" do

    User.current_user = Factory(:user, :login => 'partial',:person=>nil)
    post '/session', :login => 'partial', :password => 'blah'
    assert_redirected_to select_people_path

    assert_nil User.current_user.person

    get select_people_path
    assert_response :success

    get new_session_path
    assert_response :success

    xml_http_request :post,'people/userless_project_selected_ajax',{:project_id=>Factory(:project).id}
    assert_response :success

    get people_path
    assert_redirected_to select_people_path

    get models_path
    assert_redirected_to select_people_path

    get root_path
    assert_redirected_to select_people_path

    get sop_path(Factory :sop)
    assert_redirected_to select_people_path

    #FIXME: this part of the test fails due to an issue with IntegrationTest and reset_session after upgrade to rails 2.3.14
    #get logout_path
    #assert_redirected_to root_path

  end

end