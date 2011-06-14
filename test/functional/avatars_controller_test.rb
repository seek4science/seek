require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase
  
  fixtures :people,:users,:avatars

  include AuthenticatedTestHelper  
  
  def setup
    login_as(:quentin)    
  end

  test "show new" do
    get :new, :person_id=>people(:quentin_person).id
    assert_response :success
  end

  test "non project member can upload avatar" do
    u=Factory(:user_not_in_project)
    login_as(u)
    assert u.person.projects.empty?,"This person should not be in any projects"
    get :new, :person_id=>u.person.id
    assert_response :success

  end
  
end
