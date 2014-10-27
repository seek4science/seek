require 'test_helper'

class ProgrammesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  #for now just admins can create programmes, later we will change this
  test "new page accessible admin" do
    login_as(Factory(:admin))
    get :new
    assert_response :success
  end

  test "new page not accessible to non admin" do
    login_as(Factory(:person))
    get :new
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "only admin can destroy" do
    login_as(Factory(:person))
    prog = Factory(:programme)
    proj = prog.projects.first
    refute_nil proj
    assert_equal prog,proj.programme
    assert_no_difference("Programme.count") do
      delete :destroy,:id=>prog.id
    end
    refute_nil flash[:error]
    assert_redirected_to :root
    proj.reload
    assert_equal prog,proj.programme
  end

  test "destroy" do
    login_as(Factory(:admin))
    prog = Factory(:programme)
    proj = prog.projects.first
    refute_nil proj
    assert_equal prog,proj.programme
    assert_difference("Programme.count",-1) do
      delete :destroy,:id=>prog.id
    end
    assert_redirected_to programmes_path
    proj.reload
    assert_nil proj.programme
    assert_nil proj.programme_id
  end

  test "update" do
    login_as(Factory(:admin))
    prog = Factory(:programme,:description=>"ggggg")
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal "fish",prog.title
    assert_equal "ggggg",prog.description
  end

  test "edit page accessible to admin" do
    login_as(Factory(:admin))
    p = Factory(:programme)
    Factory(:avatar,:owner=>p)
    get :edit, :id=>p
    assert_response :success

  end

  test "edit page not accessible to non-admin" do
    login_as(Factory(:person))
    p = Factory(:programme)
    get :edit, :id=>p
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "should show index" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    p.save!
    Factory(:programme)

    get :index
    assert_response :success
  end

  test "should get show" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    p.save!

    get :show,:id=>p
    assert_response :success
  end

  test "update to default avatar" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    p.save!
    login_as(Factory(:admin))
    put :update, :id=>p, :programme=>{:avatar_id=>"0"}
    prog = assigns(:programme)
    refute_nil prog
    assert_nil prog.avatar
  end

  test "can be disabled" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    with_config_value :programmes_enabled,false do
      get :show,:id=>p
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

  test "non admin cannot spawn" do
    login_as(Factory(:person))
    prog = Factory(:programme)
    get :initiate_spawn_project,:id=>prog
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "initiate_spawn_project" do
    login_as(Factory(:admin))
    prog = Factory(:programme)
    proj1 = Factory(:project,:programme=>prog)
    proj2 = Factory(:project, :programme=>nil)
    proj3 = Factory(:project,:programme=>Factory(:programme))
    get :initiate_spawn_project,:id=>prog
    assert_response :success
    assigned_prog = assigns(:programme)
    projects = assigns(:available_projects)
    assert_equal prog,assigned_prog
    refute_includes projects, proj1
    assert_includes projects,proj2
    assert_includes projects,proj3
  end

  test "spawn project" do
    proj = Factory(:project)
    prog = Factory(:programme)
    login_as(Factory(:admin))
    assert_difference("Project.count",1) do
      post :spawn_project, :id=>prog.id,:project=>{:title=>"cheese",:description=>"mmmmmm",:web_page=>"http://google.com",:ancestor_id=>proj.id}
    end
    new_proj = assigns(:project)
    refute_nil new_proj

    assert_redirected_to project_path(new_proj)
    assert_equal prog,new_proj.programme
    assert_equal "cheese",new_proj.title
    assert_equal "mmmmmm",new_proj.description
    assert_equal "http://google.com",new_proj.web_page

    refute_nil flash[:notice]

    ancestor = assigns(:ancestor_project)
    assert_equal proj,ancestor
  end

  test "non admin cannot spawn project" do
    proj = Factory(:project)
    prog = Factory(:programme)
    login_as(Factory(:person))
    assert_no_difference("Project.count") do
      post :spawn_project, :id=>prog.id,:project=>{:title=>"cheese",:description=>"mmmmmm",:web_page=>"http://google.com",:ancestor_id=>proj.id}
    end
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "spawn project failed" do
    proj = Factory(:project)
    prog = Factory(:programme)
    login_as(Factory(:admin))
    #invalid title
    assert_no_difference("Project.count") do
      post :spawn_project, :id=>prog.id,:project=>{:title=>"",:description=>"mmmmmm",:web_page=>"http://google.com",:ancestor_id=>proj.id}
    end
    new_proj = assigns(:project)
    refute new_proj.valid?
    assert_response :success
    ancestor = assigns(:ancestor_project)
    assert_equal proj,ancestor
    assert_select "#errorExplanation" do
      assert_select "li",:text=>/Title can.*t be blank/,:count=>1
    end
  end

end
