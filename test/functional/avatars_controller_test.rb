require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @admin = Factory(:admin)
  end

  test 'show new' do
    login_as(@admin.user)
    get :new, params: { person_id: @admin.id }
    assert_response :success
  end

  test 'non project member can upload avatar' do
    u = Factory(:user_not_in_project)
    login_as(u)
    assert u.person.projects.empty?, 'This person should not be in any projects'
    get :new, params: { person_id: u.person.id }
    assert_response :success
  end

  test 'can view avatar' do
    avatar = Factory(:avatar)
    get :show, params: { person_id: avatar.owner_id, id: avatar.id }
    assert_response :success
  end

  test 'can select avatar' do
    avatar = Factory(:avatar)
    person = avatar.owner
    avatar2 = Factory(:avatar, owner: person)
    login_as(person)
    assert_equal avatar, person.avatar

    post :select, params: { person_id: person.id, id: avatar2.id }

    assert_redirected_to person_avatars_path(person)
    assert_equal avatar2, person.reload.avatar
  end

  test 'cannot select avatar if not authorized' do
    avatar = Factory(:avatar)
    person = avatar.owner
    avatar2 = Factory(:avatar, owner: person)
    person2 = Factory(:person)
    login_as(person2)
    assert_equal avatar, person.avatar

    post :select, params: { person_id: person.id, id: avatar2.id }

    assert_redirected_to person
    assert_equal avatar, person.reload.avatar
  end

  test 'can destroy avatar' do
    avatar = Factory(:avatar)
    login_as(avatar.owner)
    assert_difference('Avatar.count', -1) do
      delete :destroy, params: { person_id: avatar.owner_id, id: avatar.id }
    end
    assert_redirected_to person_avatars_path(avatar.owner)
  end

  test 'cannot destroy avatar if not authorized' do
    avatar = Factory(:avatar)
    login_as(Factory(:person))
    assert_no_difference('Avatar.count') do
      delete :destroy, params: { person_id: avatar.owner_id, id: avatar.id }
    end
    assert_redirected_to avatar.owner
  end

  test 'handles unknown person when logged out' do
    get :show, params: { person_id: 99_999, id: 4 }
    assert_response :not_found
  end

  test 'handles unknown avatar when logged out' do
    p = Factory :person
    get :show, params: { person_id: p, id: 89_878 }
    assert_response :not_found
  end

  test 'handles missing parent in route when logged out' do
    get :show, params: { id: 2 }
    assert_response :not_found
  end

  test 'breadcrumb for avatar index' do
    login_as @admin.user
    person = Factory(:person)
    Factory(:avatar, owner: person)
    get :index, params: { person_id: person.id }
    assert_response :success

    assert_select 'div.breadcrumbs', text: /Home People Index #{person.title} Avatars Index/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'a[href=?]', people_url, count: 1
      assert_select 'a[href=?]', person_url(person), count: 1
    end
  end

  test 'breadcrumb for uploading new avatar' do
    login_as @admin.user
    person = Factory(:person)
    Factory(:avatar, owner: person)
    get :new, params: { person_id: person.id }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home People Index #{person.title} Avatars Index New/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'a[href=?]', people_url, count: 1
      assert_select 'a[href=?]', person_url(person), count: 1
      assert_select 'a[href=?]', person_avatars_url(person), count: 1
    end
  end

  test 'index for programmes for admin' do
    programme = Factory(:programme, avatar: Factory(:avatar))
    Factory(:avatar, owner: programme)
    login_as(@admin)
    get :index, params: { programme_id: programme.id }
    assert_response :success
  end

  test 'index for programmes for programme admin' do
    programme_admin = Factory(:programme_administrator)
    programme = programme_admin.programmes.first
    Factory(:avatar, owner: programme)
    login_as(programme_admin)
    get :index, params: { programme_id: programme.id }
    assert_response :success
  end

  test 'index for projects for admin' do
    p = Factory(:project, avatar: Factory(:avatar))
    Factory(:avatar, owner: p)
    login_as(@admin)
    get :index, params: { project_id: p.id }
    assert_response :success
  end

  test 'index for projects for programme admin' do
    programme_admin = Factory(:programme_administrator)
    refute_empty(programme_admin.programmes.first.projects)
    project = programme_admin.programmes.first.projects.first
    Factory(:avatar, owner: project)
    login_as(programme_admin)
    get :index, params: { project_id: project.id }
    assert_response :success
  end

  test 'index for projects for project admin' do
    project_admin = Factory(:project_administrator)
    refute_empty(project_admin.projects)
    project = project_admin.projects.first
    Factory(:avatar, owner: project)
    login_as(project_admin)
    get :index, params: { project_id: project.id }
    assert_response :success
  end

  test 'index for institutions' do
    i = Factory(:institution, avatar: Factory(:avatar))
    Factory(:avatar, owner: i)
    login_as(@admin)
    get :index, params: { institution_id: i.id }
    assert_response :success
  end

  test 'new avatar for programme' do
    programme = Factory(:programme, avatar: Factory(:avatar))
    Factory(:avatar, owner: programme)
    login_as(@admin)
    get :new, params: { programme_id: programme }
    assert_response :success
  end

  test 'create avatar' do
    person = Factory(:person)

    login_as(person)
    assert_difference("Avatar.count",1) do
      post :create, params: { person_id:person, owner_type:'Person', owner_id:person.id, avatar:avatar_payload, return_to:'http://localhost:3000/fish' }
    end
    assert_nil flash[:error]
    assert_redirected_to 'http://localhost:3000/fish?use_unsaved_session_data=true'
  end

  private

  def avatar_payload
    { image_file: fixture_file_upload('files/file_picture.png', 'image/png') }
  end
end
