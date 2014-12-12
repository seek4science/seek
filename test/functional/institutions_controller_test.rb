require 'test_helper'

class InstitutionsControllerTest < ActionController::TestCase
   
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  
  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object=institutions(:ebi_inst)
  end

  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK Institutions.*/, :count=>1
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:institutions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_institution
    assert_difference('Institution.count') do
      post :create, :institution => {:title=>"test" }
    end

    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_should_show_institution
    get :show, :id => institutions(:one).id
    assert_response :success
  end

  def test_should_get_edit
    i = Factory(:institution)
    Factory(:avatar,:owner=>i)
    get :edit, :id => i

    assert_response :success
  end

  def test_should_update_institution
    put :update, :id => institutions(:one).id, :institution => { }
    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_should_destroy_institution
    institution = institutions(:four)
    get :show, :id => institution
    assert_select "span.icon", :text => /Delete institution/, :count => 1

    assert_difference('Institution.count', -1) do
      delete :destroy, :id => institution
    end

    assert_redirected_to institutions_path
  end

  def test_non_admin_should_not_destroy_institution
    login_as(:aaron)
    institution = institutions(:four)
    get :show, :id => institution.id
    assert_select "span.icon", :text => /Delete Institution/, :count => 0
    assert_select "span.disabled_icon", :text => /Delete Institution/, :count => 0
    assert_no_difference('Institution.count') do
      delete :destroy, :id => institution
    end
    assert_not_nil flash[:error]
  end

  test "can not destroy institution if it contains people" do
    institution = institutions(:four)
    work_group = Factory(:work_group, :institution => institution)
    a_person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    institution.reload
    assert_include institution.people,a_person
    get :show, :id => institution
    assert_select "span.disabled_icon", :text => /Delete Institution/, :count => 1
    assert_no_difference('Institution.count') do
      delete :destroy, :id => institution
    end
    assert_not_nil flash[:error]
  end

  #Checks that the edit option is availabe to the user
  #with can_edit_project set and he belongs to that project
  def test_user_can_edit
    login_as(:can_edit)
    get :show, :id=>institutions(:two)
    assert_select "a",:text=>/Edit Institution/,:count=>1

    get :edit, :id=>institutions(:two)
    assert_response :success

    put :update, :id=>institutions(:two).id,:institution=>{}
    assert_redirected_to institution_path(assigns(:institution))
  end

    def test_user_project_manager
    pm = Factory(:project_manager)
    institution = pm.institutions.first
    login_as(pm.user)
    get :show, :id=>institution
    assert_response :success
    assert_select "a",:text=>/Edit Institution/,:count=>1

    get :edit, :id=>institution
    assert_response :success

    put :update, :id=>institution.id,:institution=>{}
    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_user_cant_edit_project
    login_as(:cant_edit)
    get :show, :id=>institutions(:two)
    assert_select "a",:text=>/Edit Institution/,:count=>0

    get :edit, :id=>institutions(:two)
    assert_response :redirect

    #TODO: Test for update
  end

  def test_admin_can_edit
    get :show, :id=>institutions(:two)
    assert_select "a",:text=>/Edit Institution/,:count=>1

    get :edit, :id=>institutions(:two)
    assert_response :success

    put :update, :id=>institutions(:two).id,:institution=>{}
    assert_redirected_to institution_path(assigns(:institution))
  end


  test 'project manager can create institution' do
    login_as(Factory(:project_manager).user)
    get :new
    assert_response :success

    assert_difference("Institution.count") do
      post :create, :institution => {:title=>"a test institution"}
    end
  end

  test "filtered by programme via nested route" do
    assert_routing 'programmes/4/institutions',{controller:"institutions",action:"index",programme_id:"4"}
    person1 = Factory(:person)
    person2 = Factory(:person)
    prog1 = Factory(:programme,:projects=>[person1.projects.first])
    prog2 = Factory(:programme,:projects=>[person2.projects.first])

    get :index,programme_id:prog1.id
    assert_response :success

    assert_select "div.list_item_title" do
      assert_select "p > a[href=?]",institution_path(person1.institutions.first),:text=>person1.institutions.first.title
      assert_select "p > a[href=?]",institution_path(person2.institutions.first),:text=>person2.institutions.first.title,:count=>0
    end
  end

  test "project manager can edit institution, which belongs to project they are project manager, not necessary the institution they are in" do
    project_manager = Factory(:project_manager)
    assert_equal 1, project_manager.projects.count
    project  = project_manager.projects.first
    institution = Factory(:institution)
    project.institutions << institution

    assert project.institutions.include?institution
    assert !(project_manager.institutions.include?institution)

    login_as(project_manager.user)
    get :edit, :id => institution
    assert_response :success

    put :update, :id => institution, :institution => {:title => 'test'}
    assert_redirected_to institution
    institution.reload
    assert_equal 'test', institution.title
  end

  test "project manager has a 'New Institution' link in the institution index" do
    login_as(Factory(:project_manager).user)
    get :index

    assert_select "a[href=?]", new_institution_path(), :count => 1
  end

  test "non-project manager  doesnt has a 'New Institution' link in the institution index" do
    get :index
    assert_select "a[href=?]", new_institution_path(), :count => 0
  end

end

