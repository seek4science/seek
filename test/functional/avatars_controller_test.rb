require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase
  
  fixtures :people,:users,:avatars

  include AuthenticatedTestHelper  

  test "show new" do
    login_as(:quentin)
    get :new, :person_id=>people(:quentin_person).id
    assert_response :success
  end

  test "non project member can upload avatar" do
    login_as(:quentin)
    u=Factory(:user_not_in_project)
    login_as(u)
    assert u.person.projects.empty?,"This person should not be in any projects"
    get :new, :person_id=>u.person.id
    assert_response :success
  end

  test "handles unknown person when logged out" do
    get :show,:person_id=>99999,:id=>4
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test "handles unknown avatar when logged out" do
    p=Factory :person
    get :show,:person_id=>p,:id=>89878
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test "handles missing parent in route when logged out" do
    #p=Factory :person
    get :show,:id=>2
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end
  
end
