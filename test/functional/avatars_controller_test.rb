require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase


  include AuthenticatedTestHelper

  def setup
    @admin = Factory(:admin)
  end

  test "show new" do
    login_as(@admin.user)
    get :new, :person_id=>@admin.id
    assert_response :success
  end

  test "non project member can upload avatar" do
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
    get :show,:id=>2
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'breadcrumb for avatar index' do
    login_as @admin.user
    person = Factory(:person)
    Factory(:avatar,:owner=>person)
    get :index,:person_id => person.id
    assert_response :success

    assert_select 'div.breadcrumbs', :text => /Home People Index #{person.title} Edit Avatars Index/, :count => 1 do
      assert_select "a[href=?]", root_path, :count => 1
      assert_select "a[href=?]", people_url, :count => 1
      assert_select "a[href=?]", person_url(person), :count => 1
    end
  end

  test 'breadcrumb for uploading new avatar' do
    login_as @admin.user
    person = Factory(:person)
    Factory(:avatar,:owner=>person)
    get :new,:person_id => person.id
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home People Index #{person.title} Edit Avatars Index New/, :count => 1 do
      assert_select "a[href=?]", root_path, :count => 1
      assert_select "a[href=?]", people_url, :count => 1
      assert_select "a[href=?]", person_url(person), :count => 1
      assert_select "a[href=?]", person_avatars_url(person), :count => 1
    end
  end

  test "index for programmes for admin" do
    programme = Factory(:programme,:avatar=>Factory(:avatar))
    Factory(:avatar,:owner=>programme)
    login_as(@admin)
    get :index, :programme_id=>programme.id
    assert_response :success
  end

  test "index for programmes for programme admin" do
    programme_admin = Factory(:programme_administrator)
    programme = programme_admin.programmes.first
    Factory(:avatar,:owner=>programme)
    login_as(programme_admin)
    get :index, :programme_id=>programme.id
    assert_response :success
  end

  test "index for projects for admin" do
    p = Factory(:project,:avatar=>Factory(:avatar))
    Factory(:avatar,:owner=>p)
    login_as(@admin)
    get :index, :project_id=>p.id
    assert_response :success
  end

  test "index for projects for programme admin" do
    programme_admin = Factory(:programme_administrator)
    refute_empty(programme_admin.programmes.first.projects)
    project = programme_admin.programmes.first.projects.first
    Factory(:avatar,:owner=>project)
    login_as(programme_admin)
    get :index, :project_id=>project.id
    assert_response :success
  end

  test "index for projects for project admin" do
    project_admin = Factory(:project_administrator)
    refute_empty(project_admin.projects)
    project = project_admin.projects.first
    Factory(:avatar,:owner=>project)
    login_as(project_admin)
    get :index, :project_id=>project.id
    assert_response :success
  end

  test "index for institutions" do
    i = Factory(:institution,:avatar=>Factory(:avatar))
    Factory(:avatar,:owner=>i)
    login_as(@admin)
    get :index, :institution_id=>i.id
    assert_response :success
  end

  test "new avatar for programme" do
    programme = Factory(:programme,:avatar=>Factory(:avatar))
    Factory(:avatar,:owner=>programme)
    login_as(@admin)
    get :new, :programme_id=>programme
    assert_response :success
  end

  
end
