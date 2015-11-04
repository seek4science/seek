require 'test_helper'

class ProgrammesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  #this is needed to ensure the first user exists as admin, to stop it being automatically created as no fixtures are used.
  def setup
    Factory(:admin)
  end

  #for now just admins can create programmes, later we will change this
  test "new page accessible admin" do
    login_as(Factory(:admin))
    get :new
    assert_response :success
  end

  test "new page works even when no programme-less projects" do
    programme = Factory(:programme)
    work_group = Factory(:work_group, :project => programme.projects.first)
    admin = Factory(:admin, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    Project.without_programme.delete_all

    login_as(admin)
    get :new
    assert_response :success
  end

  test "new page accessible to non admin" do
    login_as(Factory(:person))
    get :new
    assert_response :success
  end

  test "new page accessible to projectless user" do
    p = Factory(:person_not_in_project)
    login_as(p)
    assert p.projects.empty?
    get :new
    assert_response :success
  end

  test "new page not accessible to logged out user" do
    get :new
    assert_redirected_to :root
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
    assert_redirected_to prog
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

  test "admin can update" do
    login_as(Factory(:admin))
    prog = Factory(:programme,:description=>"ggggg")
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal "fish",prog.title
    assert_equal "ggggg",prog.description
  end

  test "programme administrator can update" do
    person = Factory(:person)
    login_as(person)
    prog = Factory(:programme,:description=>"ggggg")
    person.is_programme_administrator=true,prog
    disable_authorization_checks{person.save!}
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal "fish",prog.title
    assert_equal "ggggg",prog.description
  end

  test "normal user cannot update" do
    login_as(Factory(:person))
    prog = Factory(:programme,:description=>"ggggg",:title=>"eeeee")
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    assert_redirected_to prog
    assert_equal "eeeee",prog.title
    assert_equal "ggggg",prog.description
  end

  test "programme administrator can add new administrators, but not remove themself" do
    pa = Factory(:programme_administrator)
    login_as(pa)
    prog = pa.programmes.first
    p1 = Factory(:person)
    p2 = Factory(:person)
    p3 = Factory(:person)

    assert pa.is_programme_administrator?(prog)
    refute p1.is_programme_administrator?(prog)
    refute p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    ids = [p1.id,p2.id].join(",")
    put :update, :id=>prog,:programme=>{:administrator_ids=>ids}

    assert_redirected_to prog

    pa.reload
    p1.reload
    p2.reload
    p3.reload

    assert pa.is_programme_administrator?(prog)
    assert p1.is_programme_administrator?(prog)
    assert p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

  end

  test "admin can add new administrators, and not remove themself" do
    admin = Factory(:programme_administrator)
    admin.is_admin=true
    disable_authorization_checks{admin.save!}
    login_as(admin)
    prog = admin.programmes.first
    p1 = Factory(:person)
    p2 = Factory(:person)
    p3 = Factory(:person)

    assert admin.is_programme_administrator?(prog)
    refute p1.is_programme_administrator?(prog)
    refute p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)

    ids = [p1.id,p2.id].join(",")
    put :update, :id=>prog,:programme=>{:administrator_ids=>ids}

    assert_redirected_to prog

    admin.reload
    p1.reload
    p2.reload
    p3.reload

    refute admin.is_programme_administrator?(prog)
    assert p1.is_programme_administrator?(prog)
    assert p2.is_programme_administrator?(prog)
    refute p3.is_programme_administrator?(prog)
  end

  test "edit page accessible to admin" do
    login_as(Factory(:admin))
    p = Factory(:programme)
    Factory(:avatar,:owner=>p)
    get :edit, :id=>p
    assert_response :success
  end

  test "edit page not accessible to user" do
    login_as(Factory(:person))
    p = Factory(:programme)
    get :edit, :id=>p
    assert_redirected_to p
    refute_nil flash[:error]
  end

  test "edit page accessible to programme_administrator" do
    person = Factory(:person)
    login_as(person)
    p = Factory(:programme)
    person.is_programme_administrator=true,p
    disable_authorization_checks{person.save!}
    get :edit, :id=>p
    assert_response :success
  end

  test "should show index" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    disable_authorization_checks{p.save!}
    Factory(:programme)

    get :index
    assert_response :success
  end

  test "should get show" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    disable_authorization_checks{p.save!}

    get :show,:id=>p
    assert_response :success
  end

  test "update to default avatar" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    disable_authorization_checks{p.save!}
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

  test "user can create programme, and becomes programme administrator" do
    p = Factory(:person)
    login_as(p)
    assert_difference("Programme.count") do
      assert_emails(1) do #activation email
        post :create, :programme=>{:title=>"A programme"}
      end
    end
    prog = assigns(:programme)
    assert_redirected_to prog
    p.reload
    assert p.is_programme_administrator?(prog)
  end

  test "admin doesn't become programme administrator by default" do
    p = Factory(:admin)
    login_as(p)
    assert_difference("Programme.count") do
      assert_emails(0) do #no email for admin creation
        post :create, :programme=>{:title=>"A programme"}
      end
    end
    prog = assigns(:programme)
    assert_redirected_to prog
    p.reload
    refute p.is_programme_administrator?(prog)
  end

  test "logged out user cannot create" do
    assert_no_difference("Programme.count") do
      post :create, :programme=>{:title=>"A programme"}
    end
    assert_redirected_to :root
  end

  test "activation review available to admin" do
    programme = Factory(:programme)
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))
    get :activation_review,:id=>programme
    assert_response :success
    assert_nil flash[:error]
  end

  test "activation review not available none admin" do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(person)
    get :activation_review,:id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "activation review not available if active" do
    programme = Factory(:programme)
    login_as(Factory(:admin))
    programme.activate
    assert programme.is_activated?
    get :activation_review,:id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'accept_activation' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))

    assert_emails(1) do
      put :accept_activation, :id=>programme
    end

    assert_redirected_to programme
    refute_nil flash[:notice]
    assert_nil flash[:error]
    programme.reload
    assert programme.is_activated?
  end

  test 'no accept_activation for none admin' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(programme_administrator)

    assert_emails(0) do
      put :accept_activation, :id=>programme
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    refute programme.is_activated?
  end

  test 'no accept_activation for not activated' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(Factory(:admin))

    assert_emails(0) do
      put :accept_activation, :id=>programme
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    assert programme.is_activated?
  end

  test 'reject activation confirmation' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))

    get :reject_activation_confirmation, :id=>programme
    assert_response :success
    assert assigns(:programme)

  end

  test 'no reject activation confirmation for already activated' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(Factory(:admin))

    get :reject_activation_confirmation, :id=>programme
    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]

  end

  test 'no reject activation confirmation for none admin' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(programme_administrator)

    get :reject_activation_confirmation, :id=>programme
    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]

  end

  test 'reject_activation' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(Factory(:admin))

    assert_emails(1) do
      put :reject_activation, :id=>programme, :programme=>{activation_rejection_reason:'rejection reason'}
    end

    assert_redirected_to programme
    refute_nil flash[:notice]
    assert_nil flash[:error]
    programme.reload
    refute programme.is_activated?
    assert_equal 'rejection reason',programme.activation_rejection_reason
  end

  test 'no reject activation for none admin' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?
    login_as(programme_administrator)

    assert_emails(0) do
      put :reject_activation, :id=>programme, :programme=>{activation_rejection_reason:'rejection reason'}
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    refute programme.is_activated?
    assert_nil programme.activation_rejection_reason
  end

  test 'no reject_activation for not activated' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.is_activated?
    login_as(Factory(:admin))

    assert_emails(0) do
      put :reject_activation, :id=>programme, :programme=>{activation_rejection_reason:'rejection reason'}
    end

    assert_redirected_to :root
    assert_nil flash[:notice]
    refute_nil flash[:error]
    programme.reload
    assert programme.is_activated?
    assert_nil programme.activation_rejection_reason
  end

  test 'none activated programme only available to administrators' do
    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    refute programme.is_activated?

    get :show, :id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]
    flash[:error]=nil

    login_as(programme_administrator)
    get :show, :id=>programme
    assert_response :success
    assert_nil flash[:error]
    logout
    flash[:error]=nil

    login_as(Factory(:admin))
    get :show, :id=>programme
    assert_response :success
    assert_nil flash[:error]
    logout
    flash[:error]=nil

    login_as(Factory(:person))
    get :show, :id=>programme
    assert_redirected_to :root
    refute_nil flash[:error]

  end


end
