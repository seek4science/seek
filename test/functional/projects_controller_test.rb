require 'test_helper'
require 'libxml'

class ProjectsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  include ActionView::Helpers::NumberHelper

  fixtures :all

  def setup
    login_as(Factory(:admin))
  end

  def rest_api_test_object
    @object=projects(:sysmo_project)
  end

  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK #{I18n.t('project').pluralize}.*/, :count=>1
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_avatar_show_in_list
    p=Factory :project
    get :index
    assert_select "div.list_items_container" do
      assert_select "div.list_item" do
        assert_select "div.list_item_avatar" do
          assert_select "a[href=?]",project_path(p)
        end
      end
    end
  end

  def test_should_create_project_with_hierarchy
    parent = Factory(:project,:title=>"Test Parent")
    assert_difference('Project.count') do
      post :create, :project => {:title=>"test",:parent_id=>parent.id}
    end

    assert_redirected_to project_path(assigns(:project))
    assert_includes assigns(:project).ancestors,parent
  end

  test "create project with default license" do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = person.programmes.first

    assert_difference("Project.count") do
      post :create, :project => {:title=>"proj with license",:default_license=>'CC-BY-SA-4.0',:programme_id=>prog.id}
    end

    project = assigns(:project)
    assert_equal 'CC-BY-SA-4.0',project.default_license
  end

  test "create project with programme" do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = person.programmes.first
    refute_nil prog

    assert_difference("Project.count") do
      post :create, :project => {:title=>"proj with prog",:programme_id=>prog.id}
    end

    project = assigns(:project)
    assert_equal [prog],project.programmes


  end

  test "create project with blank programme" do
    login_as(Factory(:admin))

    assert_difference("Project.count") do
      post :create, :project => {:title=>"proj with prog",:programme_id=>""}
    end

    project = assigns(:project)
    assert_redirected_to project
    refute_nil project
    assert_empty project.programmes


  end

  test "cannot create project with programme if not administrator of programme" do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = Factory(:programme)
    refute_nil prog

    assert_difference("Project.count") do
      post :create, :project => {:title=>"proj with prog",:programme_id=>prog.id}
    end

    project = assigns(:project)
    assert_empty project.programmes
  end

  test "programme administrator can view new" do
    login_as(Factory(:programme_administrator))
    get :new
    assert_response :success
  end

  test "programme_administrator can create project" do
    login_as(Factory(:programme_administrator))
    assert_difference('Project.count') do
      post :create, :project => {:title=>"test2"}
    end

    project = assigns(:project)
    assert_redirected_to project_path(project)
  end

  def test_should_show_project

    proj = Factory(:project)
    avatar = Factory(:avatar,:owner=>proj)
    proj.avatar = avatar
    proj.save!

    get :show, :id => proj
    assert_response :success
  end

  def test_should_get_edit
    p = Factory(:project,:avatar=>Factory(:avatar))
    Factory(:avatar,:owner=>p)
    get :edit, :id => p

    assert_response :success
  end

  def test_should_update_project
    put :update, :id => Factory(:project,:description=>"ffffff"), :project => {:title=>"pppp", :default_license=>'CC-BY-SA-4.0'}
    assert_redirected_to project_path(assigns(:project))
    proj = assigns(:project)
    assert_equal "pppp",proj.title
    assert_equal "ffffff",proj.description
    assert_equal 'CC-BY-SA-4.0',proj.default_license
  end

  def test_should_destroy_project
    project = projects(:four)
    get :show, :id => project
    assert_select "#buttons a", :text => /Delete #{I18n.t('project')}/i, :count => 1

    assert_difference('Project.count', -1) do
      delete :destroy, :id => project
    end

    assert_redirected_to projects_path
  end

  def test_admin_can_manage
    get :manage, :id=> Factory(:project)
    assert_response :success
  end

  def test_non_admin_should_not_destroy_project
    login_as(:aaron)
    project = projects(:four)
    get :show, :id => project.id
    assert_select "span.icon", :text => /Delete #{I18n.t('project')}/, :count => 0
    assert_select "span.disabled_icon", :text => /Delete #{I18n.t('project')}/, :count => 0
    assert_no_difference('Project.count') do
      delete :destroy, :id => project
    end
    assert_not_nil flash[:error]
  end

  test "can not destroy project if it contains people" do
    project = projects(:four)
    work_group = Factory(:work_group, :project => project)
    a_person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    get :show, :id => project
    assert_select "span.disabled_icon", :text => /Delete #{I18n.t('project')}/, :count => 1
    assert_no_difference('Project.count') do
      delete :destroy, :id => project
    end
    refute_nil flash[:error]
  end

  def test_non_admin_should_not_manage_projects
    login_as(:aaron)
    get :manage,:id=> Factory(:project)
    assert_not_nil flash[:error]
  end


  test "asset report with stuff in it can be accessed" do
    person = Factory(:person)
    publication = Factory(:publication, :projects=>person.projects)
    model = Factory(:model,:policy=>Factory(:public_policy),:projects=>person.projects,:organism=>Factory(:organism))

    model.save
    publication.associate(model)
    publication.save!
    project = person.projects.first

    assert_include publication.projects,project
    login_as(person)
    get :asset_report,:id=>project.id

    assert_response :success
  end

  test "asset report visible to project member" do
    person = Factory :person
    project = person.projects.first
    login_as(person.user)
    get :asset_report,:id=>project.id
    assert_response :success

  end

  test "asset report not visible to non project member" do
    person = Factory :person
    project = person.projects.first
    other_person = Factory :person
    refute project.has_member?(other_person)
    login_as(other_person.user)
    get :asset_report,:id=>project.id
    assert_redirected_to project
    assert_not_nil flash[:error]

  end

  test "asset report available to non project member if admin" do
    admin = Factory :admin
    project = Factory :project
    refute project.has_member?(admin)
    login_as(admin)
    get :asset_report, :id=>project.id
    assert_response :success
  end

  test "asset report button shown to project members" do
    person = Factory :person
    project = person.projects.first

    login_as person.user
    get :show, :id=>project.id
    assert_response :success
    assert_select "#buttons" do
      assert_select "a[href=?]",asset_report_project_path(project),:text=>"Asset report"
    end
  end

  test "asset report button not shown to anonymous users" do

    project = Factory :project

    logout
    get :show, :id=>project.id
    assert_response :success
    assert_select "#buttons" do
      assert_select "a[href=?]",asset_report_project_path(project),:text=>"Asset report",:count=>0
    end
  end

  test "asset report button not shown to none project members" do
    person = Factory :person
    project = person.projects.first
    other_person = Factory :person
    refute project.has_member?(other_person)

    login_as other_person.user
    get :show, :id=>project.id
    assert_response :success
    assert_select "#buttons" do
      assert_select "a[href=?]",asset_report_project_path(project),:text=>"Sharing report",:count=>0
    end

  end

  test "asset report button shown to admin that is not a project member" do
    admin = Factory(:admin)
    project = Factory(:project)
    refute project.has_member?(admin)
    login_as(admin)
    get :show, :id=>project.id
    assert_response :success
    assert_select "#buttons" do
      assert_select "a[href=?]",asset_report_project_path(project),:text=>"Asset report"
    end
  end

  test "should show organise link for member" do
    p=Factory :person
    login_as p.user
    get :show,:id=>p.projects.first
    assert_response :success
    assert_select "a[href=?]",project_folders_path(p.projects.first)
  end

  test "should not show organise link for non member" do
    p=Factory :person
    proj = Factory :project
    login_as p.user
    get :show,:id=>proj
    assert_response :success
    assert_select "a[href=?]",project_folders_path(p.projects.first), :count=>0
  end

  test 'should get index for non-project member, non-login user' do
    login_as(:registered_user_with_no_projects)
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)

    logout
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test 'should show project for non-project member and non-login user' do
    login_as(:registered_user_with_no_projects)
    get :show, :id=>projects(:three)
    assert_response :success

    logout
    get :show, :id=>projects(:three)
    assert_response :success
  end

  test 'non-project member and non-login user can not edit project' do
    login_as(:registered_user_with_no_projects)
    get :show, :id=>projects(:three)
    assert_response :success
    assert_select "a",:text=>/Edit Project/,:count=>0

    logout
    get :show, :id=>projects(:three)
    assert_response :success
    assert_select "a",:text=>/Edit Project/,:count=>0
  end

  def test_user_project_administrator
    project_admin = Factory(:project_administrator)
    proj = project_admin.projects.first
    login_as(project_admin.user)
    get :show, :id=>proj.id
    assert_select "a",:text=>/Edit #{I18n.t('project')}/,:count=>1

    get :edit, :id=>proj.id
    assert_response :success

    put :update, :id=>proj.id,:project=>{:title=>"fish"}
    proj = assigns(:project)
    assert_redirected_to proj
    assert_equal "fish",proj.title
  end

  def test_user_cant_edit_project
    login_as(Factory(:user))
    get :show, :id=>projects(:three)
    assert_select "a",:text=>/Edit #{I18n.t('project')}/,:count=>0

    get :edit, :id=>projects(:three)
    assert_response :redirect

    #TODO: Test for update
  end

  def test_admin_can_edit
    get :show, :id=>projects(:one)
    assert_select "a",:text=>/Edit #{I18n.t('project')}/,:count=>1

    get :edit, :id=>projects(:one)
    assert_response :success

    put :update, :id=>projects(:three).id,:project=>{}
    assert_redirected_to project_path(assigns(:project))
  end

  test "links have nofollow in sop tabs" do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    sop = Factory :sop,:description=>"http://news.bbc.co.uk",:project_ids=>[project.id],:contributor=>user
    get :show,:id=>project
    assert_response :success


    assert_select "div.list_item  div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:count=>1
    end
  end

  test "links have nofollow in data_files tabs" do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    df = Factory :data_file,:description=>"http://news.bbc.co.uk",:project_ids=>[project.id],:contributor=>user
    get :show,:id=>project
    assert_response :success

    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:count=>1
    end
  end

  test "links have nofollow in model tabs" do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    model = Factory :model,:description=>"http://news.bbc.co.uk",:project_ids=>[project.id],:contributor=>user
    get :show,:id=>project

    assert_select "div.list_item  div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:count=>1
    end
  end

  test "pals displayed in show page" do
    pal = Factory :pal,:first_name=>"A",:last_name=>"PAL"
    project = pal.projects.first
    get :show,:id=>project
    assert_select "div.box_about_actor p.pals" do
      assert_select "strong",:text=>"SysMO-DB PALs:",:count=>1
      assert_select "a",:count=>1
      assert_select "a[href=?]",person_path(pal),:text=>"A PAL",:count=>1
    end
  end

  test "asset_managers displayed in show page" do
    asset_manager = Factory(:asset_housekeeper)
    login_as asset_manager.user
    get :show,:id=>asset_manager.projects.first
    assert_select "div.box_about_actor p.asset_housekeepers" do
      assert_select "strong",:text=>"Asset housekeepers:",:count=>1
      assert_select "a",:count=>1
      assert_select "a[href=?]",person_path(asset_manager),:text=>asset_manager.name,:count=>1
    end
  end

  test "project administrators displayed in show page" do
    project_administrator = Factory(:project_administrator)
    login_as project_administrator.user
    get :show,:id=>project_administrator.projects.first
    assert_select "div.box_about_actor p.project_administrators" do
      assert_select "strong",:text=>"#{I18n.t('project')} administrators:",:count=>1
      assert_select "a",:count=>1
      assert_select "a[href=?]",person_path(project_administrator),:text=>project_administrator.name,:count=>1
    end
  end

  test "gatekeepers displayed in show page" do
    gatekeeper = Factory(:asset_gatekeeper)
    login_as gatekeeper.user
    get :show, :id => gatekeeper.projects.first
    assert_select "div.box_about_actor p.asset_gatekeepers" do
      assert_select "strong", :text => "Asset gatekeepers:", :count => 1
      assert_select "a", :count => 1
      assert_select "a[href=?]", person_path(gatekeeper), :text => gatekeeper.name, :count => 1
    end
  end

  test "dont display the roles(except pals and administrators) for people who are not the members of this showed project" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)

    asset_manager = Factory(:asset_housekeeper, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    project_administrator = Factory(:project_administrator, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    gatekeeper = Factory(:asset_gatekeeper, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    pal = Factory(:pal, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    a_person = Factory(:person)

    assert !a_person.projects.include?(project)

    login_as(a_person.user)
    get :show, :id => project
    assert_select "div.box_about_actor p" do
      assert_select "strong", :text => "Asset housekeepers:", :count => 0
      assert_select "a[href=?]", person_path(asset_manager), :text => asset_manager.name, :count => 0

      assert_select "strong", :text => "Asset gatekeepers:", :count => 0
      assert_select "a[href=?]", person_path(gatekeeper), :text => gatekeeper.name, :count => 0

      assert_select "strong", :text => "SysMO-DB PALs:", :count => 1
      assert_select "a[href=?]", person_path(pal), :text => pal.name, :count => 1

      assert_select "strong", :text => "Project administrators:", :count => 1
      assert_select "a[href=?]", person_path(project_administrator), :text => project_administrator.name, :count => 1
    end
  end

  test "filter projects by person" do
    get :index, :filter => {:person => 1}
    assert_response :success
    projects = assigns(:projects)
    assert_equal Project.all.select {|proj|proj.people.include? Person.find_by_id(1)}, projects
    assert projects.count < Project.all.count
  end

  test "no pals displayed for project with no pals" do
    get :show,:id=>projects(:myexperiment_project)
    assert_select "div.box_about_actor p.pals" do
      assert_select "strong",:text=>"SysMO-DB PALs:",:count=>1
      assert_select "a",:count=>0
      assert_select "span.none_text",:text=>"No PALs for this #{I18n.t('project')}",:count=>1
    end
  end

  test "no asset housekeepers displayed for project with no asset housekeepers" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    login_as person.user
    get :show,:id=>project
    assert_select "div.box_about_actor p.asset_housekeepers" do
      assert_select "strong",:text=>"Asset housekeepers:",:count=>1
      assert_select "a",:count=>0
      assert_select "span.none_text",:text=>"No Asset housekeepers for this #{I18n.t('project')}",:count=>1
    end
  end

  test "no project administrator displayed for project with no project managers" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    login_as person.user
    get :show,:id=>project
    assert_select "div.box_about_actor p.project_administrators" do
      assert_select "strong",:text=>"#{I18n.t('project')} administrators:",:count=>1
      assert_select "a",:count=>0
      assert_select "span.none_text",:text=>"No #{I18n.t('project')} administrators for this #{I18n.t('project')}",:count=>1
    end
  end

  test "no gatekeepers displayed for project with no gatekeepers" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    login_as person.user
    get :show,:id=>project
    assert_select "div.box_about_actor p.asset_gatekeepers" do
      assert_select "strong",:text=>"Asset gatekeepers:",:count=>1
      assert_select "a",:count=>0
      assert_select "span.none_text",:text=>"No Asset gatekeepers for this #{I18n.t('project')}",:count=>1
    end
  end

  test "non admin cannot administer project" do
    person = Factory(:person)
    login_as(person.user)
    get :admin,:id=>person.projects.first
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "admin can administer project" do
    get :admin,:id=>projects(:sysmo_project)
    assert_response :success
    assert_nil flash[:error]
  end

  test "non admin has no option to administer project" do
    user = Factory :user
    assert_equal 1,user.person.projects.count
    project = user.person.projects.first
    login_as(user)
    get :show,:id=>project
    assert_select "#buttons" do
      assert_select "a[href=?]",admin_members_project_path(project),:count=>0
    end
  end

  test "admin has option to administer project" do
    admin = Factory :admin
    assert_equal 1,admin.projects.count
    project = admin.projects.first
    login_as(admin.user)
    get :show,:id=>project
    assert_select "#buttons" do
      assert_select "a[href=?]",admin_members_project_path(project),:text=>/Administer #{I18n.t('project')} members/,:count=>1
    end
  end


  test "changing default policy" do
    login_as(:quentin)

    person = people(:aaron_person)
    project = projects(:four)
    assert_nil project.default_policy_id #check theres no policy to begin with

    #Set up the sharing param to share with one person (aaron)
    sharing = {}
    sharing[:permissions] = {}
    sharing[:permissions][:contributor_types] = ActiveSupport::JSON.encode(["Person"])
    sharing[:permissions][:values] = ActiveSupport::JSON.encode({"Person"=>{(person.id)=>{"access_type"=>0}}})
    sharing[:sharing_scope] = Policy::EVERYONE
    sharing["access_type_#{sharing[:sharing_scope]}"] = Policy::VISIBLE
    put :update, :id => project.id, :project => valid_project, :sharing => sharing

    project = Project.find(project.id)
    assert_redirected_to project
    assert project.default_policy_id
    assert Permission.find_by_policy_id(project.default_policy).contributor_id == person.id
  end

  test 'project administrator can administer their projects' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    login_as(project_administrator.user)

    get :show, :id => project
    assert_response :success
    assert_select "a[href=?]",admin_members_project_path(project), :text => /Administer #{I18n.t('project')} members/, :count => 1

    get :admin, :id => project
    assert_response :success

    new_institution = Institution.create(:title => 'a test institution', :country => 'Canada')
    put :update, :id => project, :project => {:institution_ids => (project.institutions + [new_institution]).collect(&:id)}
    assert_redirected_to project
    project.reload
    assert project.institutions.include?new_institution
  end

  test 'project administrator can not administer the projects that they are not in' do
    project_administrator = Factory(:project_administrator)
    a_project = Factory(:project)
    assert !(project_administrator.projects.include?a_project)
    login_as(project_administrator.user)

    get :show, :id => a_project
    assert_response :success
    assert_select "a", :text => /Project administration/, :count => 0

    get :admin, :id => a_project
    assert_redirected_to :root
    assert_not_nil flash[:error]

    new_institution = Institution.create(:title => 'a test institution')
    put :update, :id => a_project, :project => {:institution_ids => (a_project.institutions + [new_institution]).collect(&:id)}
    assert_redirected_to :root
    assert_not_nil flash[:error]
    a_project.reload
    assert !(a_project.institutions.include?new_institution)
  end

  test "jerm details not shown if disabled" do
    project = Factory(:project)
    with_config_value :jerm_enabled,false do
      get :admin, :id=>project.id
      assert_response :success
      assert_select "div#details_for_jerm", :count=>0
    end
  end

  test "jerm details shown is enabled" do
    project = Factory(:project)
    with_config_value :jerm_enabled,true do
      get :admin, :id=>project.id
      assert_response :success
      assert_select "div#details_for_jerm", :count=>1
    end
  end

  test 'project administrator can only see all institutions' do
    project_admin = Factory(:project_administrator)
    project = project_admin.projects.first
    login_as(project_admin.user)
    Factory(:institution)

    get :admin, :id => project
    assert_response :success
    Institution.all.each do |institution|
      assert_select "input[type='checkbox'][id='institution_#{institution.id}'][value='#{institution.id}']", :count => 1
    end
  end

  test 'project administrator can assign all institutions to their project' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    login_as(project_administrator.user)
    a_institution = Factory(:institution)

    put :update, :id => project, :project => {:institution_ids => Institution.all.collect(&:id)}
    assert_redirected_to project
    project.reload
    assert_equal Institution.count, project.institutions.count
  end

  test 'project administrator can not administer sharing policy' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    policy = project.default_policy

    sharing = {}
    sharing[:sharing_scope] = Policy::EVERYONE
    sharing["access_type_#{sharing[:sharing_scope]}"] = Policy::VISIBLE

    assert_not_equal policy.sharing_scope, sharing[:sharing_scope]
    assert_not_equal policy.access_type, sharing["access_type_#{sharing[:sharing_scope]}"]

    login_as(project_administrator.user)
    put :update, :id => project.id, :project => valid_project, :sharing => sharing
    project.reload
    assert_redirected_to project
    assert_not_equal project.default_policy.sharing_scope, sharing[:sharing_scope]
    assert_not_equal project.default_policy.access_type, sharing["access_type_#{sharing[:sharing_scope]}"]
  end

  test 'project administrator can not administer jerm detail' do
    with_config_value :jerm_enabled,true do
      project_administrator = Factory(:project_administrator)
      project = project_administrator.projects.first
      assert_nil project.site_root_uri
      assert_nil project.site_username
      assert_nil project.site_password

      login_as(project_administrator.user)
      put :update, :id => project.id, :project => {:site_root_uri => 'test', :site_username => 'test', :site_password => 'test'}

      project.reload
      assert_redirected_to project
      assert_nil project.site_root_uri
      assert_nil project.site_username
      assert_nil project.site_password
    end
  end

  test "unassign institution out of project" do
    project = Factory(:project)
    project.institutions << Factory(:institution)

    login_as(:quentin)

    put :update, :id => project, :project => {:institution_ids => []}
    assert_redirected_to project
    assert_nil flash[:error]
    project.reload
    assert project.institutions.empty?
  end

  test "should not unassign institution out of project if there are people in this workgroup" do
    wg=WorkGroup.find(1)
    assert !wg.people.empty?
    project = wg.project

    login_as(:quentin)
    #exception is rescued
    assert_no_difference('WorkGroup.count') do
      post :update, :id => project, :project => {:institution_ids => []}
      assert_redirected_to project
      assert_not_nil flash[:error]
    end
    project.reload
    assert !project.institutions.empty?
  end


  test "can not remove workgroup if it contains people" do
    project = Factory(:project)
    institution = Factory(:institution)
    work_group = Factory(:work_group, :project => project, :institution => institution)
    a_person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    assert !project.institutions.empty?
    assert !work_group.people.empty?

    assert_no_difference('WorkGroup.count') do
      post :update, :id => project, :project => {:institution_ids => []}
    end

    assert_redirected_to project
    assert_not_nil flash[:error]
    assert !project.reload.institutions.empty?
    assert !work_group.reload.people.empty?
  end

  test 'email job created when edited by a member' do
    person = Factory(:person)
    project = person.projects.first
    login_as(person)
    Delayed::Job.delete_all

    post :update, :id=>project, :project => {:description=>"sdfkuhsdfkhsdfkhsdf"}

    assert ProjectChangedEmailJob.new(project).exists?
  end

  test 'no email job created when edited by an admin' do
    person = Factory(:admin)
    project = person.projects.first
    login_as(person)
    Delayed::Job.delete_all

    post :update, :id=>project, :project => {:description=>"sdfkuhsdfkhsdfkhsdf"}

    refute ProjectChangedEmailJob.new(project).exists?
  end

  test 'no email job created when edited by an project administrator' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)
    Delayed::Job.delete_all

    post :update, :id=>project, :project => {:description=>"sdfkuhsdfkhsdfkhsdf"}

    refute ProjectChangedEmailJob.new(project).exists?
  end

  test "projects belonging to an institution through nested route" do
    assert_routing "institutions/3/projects",{controller:"projects",action:"index",institution_id:"3"}

    project = Factory(:project)
    institution = Factory(:institution)
    Factory(:work_group, :project => project, :institution => institution)
    project2 = Factory(:project)
    Factory(:work_group, :project => project2, :institution => Factory(:institution))

    get :index,institution_id:institution.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(project),:text=>project.title
      assert_select "a[href=?]",project_path(project2),:text=>project2.title,:count=>0
    end

  end

  test "projects filtered by data file using nested routes" do
    assert_routing "data_files/3/projects",{controller:"projects",action:"index",data_file_id:"3"}
    df1 = Factory(:data_file,policy:Factory(:public_policy))
    df2 = Factory(:data_file,policy:Factory(:public_policy))
    refute_equal df1.projects,df2.projects
    get :index,data_file_id:df1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(df1.projects.first),:text=>df1.projects.first.title
      assert_select "a[href=?]",project_path(df2.projects.first),:text=>df2.projects.first.title,:count=>0
    end
  end

  test "projects filtered by models using nested routes" do
    assert_routing "models/3/projects",{controller:"projects",action:"index",model_id:"3"}
    model1 = Factory(:model,policy:Factory(:public_policy))
    model2 = Factory(:model,policy:Factory(:public_policy))
    refute_equal model1.projects,model2.projects
    get :index,model_id:model1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(model1.projects.first),:text=>model1.projects.first.title
      assert_select "a[href=?]",project_path(model2.projects.first),:text=>model2.projects.first.title,:count=>0
    end
  end

  test "projects filtered by sops using nested routes" do
    assert_routing "sops/3/projects",{controller:"projects",action:"index",sop_id:"3"}
    sop1 = Factory(:sop,policy:Factory(:public_policy))
    sop2 = Factory(:sop,policy:Factory(:public_policy))
    refute_equal sop1.projects,sop2.projects
    get :index,sop_id:sop1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(sop1.projects.first),:text=>sop1.projects.first.title
      assert_select "a[href=?]",project_path(sop2.projects.first),:text=>sop2.projects.first.title,:count=>0
    end
  end

  test "projects filtered by publication using nested routes" do
    assert_routing "publications/3/projects",{controller:"projects",action:"index",publication_id:"3"}
    pub1 = Factory(:publication)
    pub2 = Factory(:publication)
    refute_equal pub1.projects,pub2.projects
    get :index,publication_id:pub1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(pub1.projects.first),:text=>pub1.projects.first.title
      assert_select "a[href=?]",project_path(pub2.projects.first),:text=>pub2.projects.first.title,:count=>0
    end
  end

  test "projects filtered by events using nested routes" do
    assert_routing "events/3/projects",{controller:"projects",action:"index",event_id:"3"}
    event1 = Factory(:event)
    event2 = Factory(:event)
    refute_equal event1.projects,event2.projects
    get :index,event_id:event1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(event1.projects.first),:text=>event1.projects.first.title
      assert_select "a[href=?]",project_path(event2.projects.first),:text=>event2.projects.first.title,:count=>0
    end
  end

  test "projects filtered by strain using nested routes" do
    assert_routing "strains/2/projects",{controller:"projects",action:"index",strain_id:"2"}
    strain1=Factory(:strain,:policy=>Factory(:public_policy))
    strain2=Factory(:strain,:policy=>Factory(:public_policy))
    project1 = strain1.projects.first
    project2 = strain2.projects.first
    refute_empty strain1.projects
    refute_empty strain2.projects
    refute_equal project1,project2

    assert_include project1.strains,strain1
    assert_include project2.strains,strain2

    get :index,strain_id:strain1.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]",project_path(strain1.projects.first),:text=>strain1.projects.first.title
      assert_select "a[href=?]",project_path(strain2.projects.first),:text=>strain2.projects.first.title,:count=>0
    end

  end

  test "programme shown in list" do
    prog = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    get :index
    assert_select "p.list_item_attribute" do
      assert_select "b",:text=>/#{I18n.t('programme')}/i
      assert_select "a[href=?]",programme_path(prog),:text=>prog.title,:count=>2
    end

  end

  test "programme not shown in list when disabled" do
    prog = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    with_config_value :programmes_enabled,false do
      get :index
      assert_select "p.list_item_attribute" do
        assert_select "b",:text=>/#{I18n.t('programme')}/i, :count=>0
        assert_select "a[href=?]",programme_path(prog),:text=>prog.title,:count=>0
      end
    end
  end

  test "programme shown" do
    prog = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    get :show, :id=>prog.projects.first
    assert_select "strong",:text=>/#{I18n.t('programme')}/i, :count=>1
    assert_select "a[href=?]",programme_path(prog),:text=>prog.title,:count=>1
  end

  test "programme not shown when disabled" do
    prog = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    with_config_value :programmes_enabled,false do
      get :show, :id=>prog.projects.first
      assert_select "strong",:text=>/#{I18n.t('programme')}/i, :count=>0
      assert_select "a[href=?]",programme_path(prog),:text=>prog.title,:count=>0
    end
  end

  test "get as json" do
    proj = Factory(:project,:title=>"fishing project",:description=>"investigating fishing")
    get :show,:id=>proj,:format=>"json"
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal "fishing project",json["title"]
    assert_equal "investigating fishing",json["description"]
  end

  test "admin members available to admin" do
    login_as(Factory(:admin))
    p=Factory(:project)
    get :admin_members,:id=>p
    assert_response :success
  end

  test "admin_members available to project administrator" do
    person = Factory(:project_administrator)
    login_as(person)
    project = person.projects.first
    get :admin_members,:id=>project
    assert_response :success
  end

  test "admin members not available to normal person" do
    login_as(Factory(:person))
    p=Factory(:project)
    get :admin_members,:id=>p
    assert_redirected_to :root
  end

  test "update members" do
    login_as(Factory(:admin))
    project = Factory(:project)
    wg = Factory(:work_group, :project => project)
    group_membership = Factory(:group_membership, :work_group => wg)
    person = Factory(:person, :group_memberships => [group_membership])
    group_membership2 = Factory(:group_membership, :work_group => wg)
    person2 = Factory(:person, :group_memberships => [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)

    assert_no_difference("GroupMembership.count") do #2 deleted, 2 added
      assert_no_difference("WorkGroup.count") do # 1 empty group will be deleted, 1 will be added
        post :update_members,
             :id=>project,
             :group_memberships_to_remove=>[group_membership.id,group_membership2.id],
             :people_and_institutions_to_add=>[{"person_id"=>new_person.id,"institution_id"=>new_institution.id}.to_json,{"person_id"=>new_person2.id,"institution_id"=>new_institution.id}.to_json]
        assert_redirected_to project_path(project)
        assert_nil flash[:error]
        refute_nil flash[:notice]
      end
    end

    assert_includes project.institutions, new_institution
    assert_includes project.people, new_person
    assert_includes project.people, new_person2

    person.reload
    new_person.reload
    new_person2.reload

    refute_includes person.projects,project
    refute_includes person2.projects,project
    assert_includes new_person.projects,project
    assert_includes new_person2.projects,project
    assert_includes new_person.institutions,new_institution
    assert_includes new_person2.institutions,new_institution

    assert_includes new_person.project_subscriptions.collect(&:project),project
    assert_includes new_person2.project_subscriptions.collect(&:project),project

    refute_includes person.project_subscriptions.collect(&:project),project
    refute_includes person2.project_subscriptions.collect(&:project),project

  end

  test "update members as project administrator" do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    wg = Factory(:work_group, :project => project)
    group_membership = Factory(:group_membership, :work_group => wg)
    person = Factory(:person, :group_memberships => [group_membership])
    group_membership2 = Factory(:group_membership, :work_group => wg)
    person2 = Factory(:person, :group_memberships => [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    assert_no_difference("GroupMembership.count") do #2 deleted, 2 added
      assert_no_difference("WorkGroup.count") do # 1 empty group will be deleted, 1 will be added
        post :update_members,
             :id=>project,
             :group_memberships_to_remove=>[group_membership.id,group_membership2.id],
             :people_and_institutions_to_add=>[{"person_id"=>new_person.id,"institution_id"=>new_institution.id}.to_json,{"person_id"=>new_person2.id,"institution_id"=>new_institution.id}.to_json]
        assert_redirected_to project_path(project)
        assert_nil flash[:error]
        refute_nil flash[:notice]
      end
    end

    assert_includes project.institutions, new_institution
    assert_includes project.people, new_person
    assert_includes project.people, new_person2

    person.reload
    new_person.reload
    new_person2.reload

    refute_includes person.projects,project
    refute_includes person2.projects,project
    assert_includes new_person.projects,project
    assert_includes new_person2.projects,project
    assert_includes new_person.institutions,new_institution
    assert_includes new_person2.institutions,new_institution
  end

  test "can flag and unflag members as leaving as project administrator" do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    wg = Factory(:work_group, :project => project)
    group_membership = Factory(:group_membership, :work_group => wg)
    person = Factory(:person, :group_memberships => [group_membership])
    former_group_membership = Factory(:group_membership, :time_left_at => 10.days.ago, :work_group => wg)
    former_person = Factory(:person, :group_memberships => [former_group_membership])
    assert_no_difference("GroupMembership.count") do
      post :update_members,
           :id => project,
           :memberships_to_flag => { group_membership.id.to_s => { :time_left_at => 1.day.ago },
                                     former_group_membership.id.to_s => { :time_left_at => '' }}
      assert_redirected_to project_path(project)
      assert_nil flash[:error]
      refute_nil flash[:notice]
    end

    assert group_membership.reload.has_left
    assert !former_group_membership.reload.has_left
  end

  test "cannot flag members of other projects as leaving" do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    wg = Factory(:work_group, :project => Factory(:project))
    group_membership = Factory(:group_membership, :work_group => wg)
    person = Factory(:person, :group_memberships => [group_membership])

    assert !group_membership.reload.has_left
    assert project != wg.project

    post :update_members,
         :id => project,
         :memberships_to_flag => { group_membership.id.to_s => { :time_left_at => 1.day.ago }}

    assert_redirected_to project_path(project)
    assert_nil flash[:error]
    refute_nil flash[:notice]
    assert !group_membership.reload.has_left
  end

  test "project administrator can access admin member roles" do
    pa = Factory(:project_administrator)
    login_as(pa)
    project = pa.projects.first
    get :admin_member_roles, :id=>project
    assert_response :success
  end

  test "admin can access admin member roles" do
    pa = Factory(:admin)
    login_as(pa)
    project = pa.projects.first
    get :admin_member_roles, :id=>project
    assert_response :success
  end

  test "normal user cannot access admin member roles" do
    pa = Factory(:person)
    login_as(pa)
    project = pa.projects.first
    get :admin_member_roles, :id=>project
    assert_redirected_to :root
    refute_nil flash[:error]
  end


  test "update member admin roles" do
    pa = Factory(:programme_administrator)
    login_as(pa)
    project = pa.projects.first
    person = Factory(:person)
    person.add_to_project_and_institution(project,Factory(:institution))
    person.save!

    person2 = Factory(:person)
    person2.add_to_project_and_institution(project,Factory(:institution))
    person2.save!
    person2.reload

    assert_equal [pa,person,person2].sort, project.people.sort
    refute person.is_asset_gatekeeper?(project)
    refute person.is_asset_housekeeper?(project)
    refute person.is_project_administrator?(project)
    refute person.is_pal?(project)
    refute person2.is_asset_gatekeeper?(project)
    refute person2.is_asset_housekeeper?(project)
    refute person2.is_project_administrator?(project)
    refute person2.is_pal?(project)

    ids = "#{person.id},#{person2.id}"

    post :update_members,
         :id=>project,:project=>{:project_administrator_ids=>ids,:asset_gatekeeper_ids=>ids,:asset_housekeeper_ids=>ids,:pal_ids=>ids}

    assert_redirected_to project_path(project)
    assert_nil flash[:error]
    refute_nil flash[:notice]

    person.reload
    person2.reload
    assert_equal [pa,person,person2].sort, project.people.sort

    assert person.is_asset_gatekeeper?(project)
    assert person.is_asset_housekeeper?(project)
    assert person.is_project_administrator?(project)
    assert person.is_pal?(project)
    assert person2.is_asset_gatekeeper?(project)
    assert person2.is_asset_housekeeper?(project)
    assert person2.is_project_administrator?(project)
    assert person2.is_pal?(project)


  end

  test "person who cannot administer project cannot update members" do
    login_as(Factory(:person))
    project = Factory(:project)
    wg = Factory(:work_group, :project => project)
    group_membership = Factory(:group_membership, :work_group => wg)
    person = Factory(:person, :group_memberships => [group_membership])
    group_membership2 = Factory(:group_membership, :work_group => wg)
    person2 = Factory(:person, :group_memberships => [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    assert_no_difference("GroupMembership.count") do
      assert_no_difference("WorkGroup.count") do
        post :update_members,
             :id=>project,
             :group_memberships_to_remove=>[group_membership.id,group_membership2.id],
             :people_and_institutions_to_add=>[{"person_id"=>new_person.id,"institution_id"=>new_institution.id}.to_json,{"person_id"=>new_person2.id,"institution_id"=>new_institution.id}.to_json]
        assert_redirected_to :root
        refute_nil flash[:error]
      end
    end

    person.reload
    new_person.reload
    new_person2.reload

    assert_includes person.projects,project
    assert_includes person2.projects,project
    refute_includes new_person.projects,project
    refute_includes new_person2.projects,project
    refute_includes new_person.institutions,new_institution
    refute_includes new_person2.institutions,new_institution

  end

  test 'assigns current user and sets as administrator if requested on create' do
    person = Factory(:programme_administrator_not_in_project)
    institution = Factory(:institution)
    login_as(person)
    assert_difference('Project.count') do
      post :create, :project => {:title=>"test2"},:default_member=>{:add_to_project=>"1",:institution_id=>institution.id}
    end

    assert project=assigns(:project)
    person.reload

    assert_includes person.projects,project
    assert_includes person.institutions, institution
    assert person.is_project_administrator?(project)
  end

  test 'does not assign current user and sets as administrator if not requested on create' do
    person = Factory(:programme_administrator_not_in_project)
    institution = Factory(:institution)
    login_as(person)
    assert_difference('Project.count') do
      post :create, :project => {:title=>"test2"},:default_member=>{:add_to_project=>"0",:institution_id=>institution.id}
    end

    assert project=assigns(:project)
    person.reload

    refute_includes person.projects,project
    refute_includes person.institutions, institution
    refute person.is_project_administrator?(project)
  end

  test 'institution association removed after last member removed' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    institution1 = Factory(:institution)
    institution2 = Factory(:institution)
    wg1 = Factory(:work_group, :project => project, :institution => institution1)
    wg2 = Factory(:work_group, :project => project, :institution => institution2)
    group_membership1 = Factory(:group_membership, :work_group => wg1)
    group_membership2 = Factory(:group_membership, :work_group => wg2)
    person1 = Factory(:person, :group_memberships => [group_membership1])
    person2 = Factory(:person, :group_memberships => [group_membership2])

    assert_includes project.institutions, institution1
    assert_includes project.institutions, institution2

    assert_difference("GroupMembership.count", -1) do
      assert_difference("WorkGroup.count", -1) do
        post :update_members,
             :id=>project,
             :group_memberships_to_remove=>[group_membership2.id],
             :people_and_institutions_to_add=>[]
        assert_redirected_to project_path(project)
        assert_nil flash[:error]
        refute_nil flash[:notice]
      end
    end

    project.reload
    assert_includes project.people, person1
    assert_not_includes project.people, person2
    assert_includes project.institutions, institution1
    assert_not_includes project.institutions, institution2
  end

  test 'non-empty institution is not removed when member removed' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    institution1 = Factory(:institution)
    wg1 = Factory(:work_group, :project => project, :institution => institution1)
    group_membership1 = Factory(:group_membership, :work_group => wg1)
    group_membership2 = Factory(:group_membership, :work_group => wg1)
    person1 = Factory(:person, :group_memberships => [group_membership1])
    person2 = Factory(:person, :group_memberships => [group_membership2])

    assert_includes project.institutions, institution1

    assert_difference("GroupMembership.count", -1) do
      assert_no_difference("WorkGroup.count") do
        post :update_members,
             :id=>project,
             :group_memberships_to_remove=>[group_membership2.id],
             :people_and_institutions_to_add=>[]
        assert_redirected_to project_path(project)
        assert_nil flash[:error]
        refute_nil flash[:notice]
      end
    end

    project.reload
    assert_includes project.people, person1
    assert_not_includes project.people, person2
    assert_includes project.institutions, institution1
  end

  test 'activity logging' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    assert_difference('ActivityLog.count') do
      get :show,id:project.id
    end

    log = ActivityLog.last
    assert_equal project,log.activity_loggable
    assert_equal 'show', log.action
    assert_equal person.user, log.culprit

    assert_difference('ActivityLog.count') do
      put :update,id:project.id,project:{title:'fishy project'}
    end

    log = ActivityLog.last
    assert_equal project,log.activity_loggable
    assert_equal 'update', log.action
    assert_equal person.user, log.culprit


  end

  test 'can get storage usage' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    data_file = Factory(:data_file, :project_ids => [project.id])
    size = data_file.content_blob.file_size
    assert size > 0

    login_as(project_administrator)
    get :storage_report, id: project.id
    assert_response :success
    assert_nil flash[:error]
    assert_select 'strong', text: number_to_human_size(size)
  end

  test 'non admin cannot get storage usage' do
    person = Factory(:person)
    project = person.projects.first

    login_as(person)
    get :storage_report, id: project.id
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'no resource count stats' do
    get :index
    assert_response :success
    assert_select '#resource-count-stats',:count=>0
  end

  private

  def valid_project
    return {}
  end
end
