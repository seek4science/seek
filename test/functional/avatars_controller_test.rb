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

  test 'breadcrumb for avatar index' do
    login_as(:quentin)
    person = Factory(:person)
    get :index,:person_id => person.id
    assert_response :success

    assert_select 'div.breadcrumbs', :text => /Home > People Index > #{person.title} > Edit > Avatars Index/, :count => 1 do
      assert_select "a[href=?]", root_path, :count => 1
      assert_select "a[href=?]", people_url, :count => 1
      assert_select "a[href=?]", person_url(person), :count => 1
    end
  end

  test 'breadcrumb for uploading new avatar' do
    login_as(:quentin)
    person = Factory(:person)
    post :new,:person_id => person.id
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home > People Index > #{person.title} > Edit > Avatars Index > New/, :count => 1 do
      assert_select "a[href=?]", root_path, :count => 1
      assert_select "a[href=?]", people_url, :count => 1
      assert_select "a[href=?]", person_url(person), :count => 1
      assert_select "a[href=?]", person_avatars_url(person)
    end
  end
  
end
