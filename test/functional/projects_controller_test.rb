require 'test_helper'
require 'libxml'

class ProjectsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  include ActionView::Helpers::NumberHelper
  include SharingFormTestHelper

  fixtures :all

  def setup
    login_as(Factory(:admin))
  end

  def rest_api_test_object
    @object = projects(:sysmo_project)
  end

  def test_title
    get :index
    assert_select 'title', text: I18n.t('project').pluralize, count: 1
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

  test 'get new with programme' do
    programme_admin = Factory(:programme_administrator)
    prog = programme_admin.programmes.first
    refute_nil prog
    login_as(programme_admin)
    get :new, params: { programme_id:prog.id }
    assert_response :success
    assert_select "select#project_programme_id" do
      assert_select "option[selected!='selected']", count:0
      assert_select "option[selected='selected'][value='#{prog.id}']",count:1
    end
  end

  def test_avatar_show_in_list
    p = Factory :project
    get :index
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_avatar' do
          assert_select 'a[href=?]', project_path(p)
        end
      end
    end
  end

  def test_should_create_project_with_hierarchy
    parent = Factory(:project, title: 'Test Parent')
    assert_difference('Project.count') do
      post :create, params: { project: { title: 'test', parent_id: parent.id } }
    end

    assert_redirected_to project_path(assigns(:project))
    assert_includes assigns(:project).ancestors, parent
  end

  test 'create project with default license' do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = person.programmes.first

    assert_difference('Project.count') do
      post :create, params: { project: { title: 'proj with license', default_license: 'CC-BY-SA-4.0', programme_id: prog.id } }
    end

    project = assigns(:project)
    assert_equal 'CC-BY-SA-4.0', project.default_license
  end

  test 'create project with default policy' do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = person.programmes.first

    assert_difference('Project.count') do
      post :create, params: { project: { title: 'proj with policy', programme_id: prog.id,use_default_policy:'1' }, policy_attributes: valid_sharing }
    end

    project = assigns(:project)

    assert_redirected_to project
    assert project.default_policy
    assert project.use_default_policy
    assert_nil project.default_policy.sharing_scope
  end

  test 'create project with programme' do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = person.programmes.first
    refute_nil prog

    assert_difference('Project.count') do
      post :create, params: { project: { title: 'proj with prog', programme_id: prog.id } }
    end

    project = assigns(:project)
    assert_equal [prog], project.programmes
  end

  test 'create project with start and end dates and funding codes' do
    person = Factory(:admin)
    login_as(person)

    assert_difference('Project.count') do
      post :create, params: { project: { title: 'proj with dates', start_date:'2018-11-01', end_date:'2018-11-18',
                                         funding_codes: 'aaa,bbb' } }
    end

    project = assigns(:project)
    assert_equal Date.parse('2018-11-01'), project.start_date
    assert_equal Date.parse('2018-11-18'), project.end_date

    assert_equal 2, project.funding_codes.length
    assert_includes project.funding_codes, 'aaa'
    assert_includes project.funding_codes, 'bbb'
  end

  test 'can add and remove funding codes' do
    login_as(Factory(:admin))
    project = Factory(:project)

    assert_difference('Annotation.count', 2) do
      put :update, params: { id: project, project: { funding_codes: '1234,abcd' } }
    end

    assert_redirected_to project

    assert_equal 2, assigns(:project).funding_codes.length
    assert_includes assigns(:project).funding_codes, '1234'
    assert_includes assigns(:project).funding_codes, 'abcd'

    assert_difference('Annotation.count', -2) do
      put :update, params: { id: project, project: { funding_codes: '' } }
    end

    assert_redirected_to project

    assert_equal 0, assigns(:project).funding_codes.length
  end

  test 'create project with blank programme' do
    login_as(Factory(:admin))

    assert_difference('Project.count') do
      post :create, params: { project: { title: 'proj with prog', programme_id: '' } }
    end

    project = assigns(:project)
    assert_redirected_to project
    refute_nil project
    assert_empty project.programmes
  end

  test 'cannot create project with programme if not administrator of programme' do
    person = Factory(:programme_administrator)
    login_as(person)
    prog = Factory(:programme)
    refute_nil prog

    assert_difference('Project.count') do
      post :create, params: { project: { title: 'proj with prog', programme_id: prog.id } }
    end

    project = assigns(:project)
    assert_empty project.programmes
  end

  test 'programme administrator can view new' do
    login_as(Factory(:programme_administrator))
    get :new
    assert_response :success
  end

  test 'programme_administrator can create project' do
    login_as(Factory(:programme_administrator))
    assert_difference('Project.count') do
      post :create, params: { project: { title: 'test2' } }
    end

    project = assigns(:project)
    assert_redirected_to project_path(project)
  end

  test 'programme administrator sees admin openbis link' do
    proj_admin = Factory(:project_administrator)
    login_as(proj_admin)
    project = proj_admin.projects.first
    another_project = Factory(:project)

    with_config_value(:openbis_enabled, true) do
      get :show, params: { id: project }
      assert_response :success
      assert_select 'ul#item-admin-menu' do
        assert_select 'a[href=?]', project_openbis_endpoints_path(project), text: /Administer openBIS/
      end

      get :show, params: { id: another_project }
      assert_response :success
      assert_select 'a[href=?]', project_openbis_endpoints_path(project), count: 0
    end

    with_config_value(:openbis_enabled, false) do
      get :show, params: { id: project }
      assert_response :success
      assert_select 'ul#item-admin-menu' do
        assert_select 'a[href=?]', project_openbis_endpoints_path(project), text: /Administer openBIS/, count: 0
      end
    end
  end

  def test_should_show_project
    proj = Factory(:project)
    avatar = Factory(:avatar, owner: proj)
    proj.avatar = avatar
    proj.save!

    get :show, params: { id: proj }
    assert_response :success
  end

  def test_should_get_edit
    p = Factory(:project, avatar: Factory(:avatar))
    Factory(:avatar, owner: p)
    get :edit, params: { id: p }

    assert_response :success
  end

  test 'should get edit for project with no policy' do
    p = Factory(:project, default_policy: nil)

    assert_nil p.default_policy

    get :edit, params: { id: p }

    assert_response :success
  end

  def test_should_update_project
    put :update, params: { id: Factory(:project, description: 'ffffff'), project: { title: 'pppp', default_license: 'CC-BY-SA-4.0' } }
    assert_redirected_to project_path(assigns(:project))
    proj = assigns(:project)
    assert_equal 'pppp', proj.title
    assert_equal 'ffffff', proj.description
    assert_equal 'CC-BY-SA-4.0', proj.default_license
  end

  def test_should_destroy_project
    project = projects(:four)
    assert project.can_delete?
    get :show, params: { id: project }
    assert_select '#buttons a', text: /Delete #{I18n.t('project')}/i, count: 1

    assert_difference('Project.count', -1) do
      delete :destroy, params: { id: project }
    end

    assert_redirected_to projects_path
  end

  def test_admin_can_manage
    get :manage, params: { id: Factory(:project) }
    assert_response :success
  end

  def test_non_admin_should_not_destroy_project
    login_as(:aaron)
    project = projects(:four)
    get :show, params: { id: project.id }
    assert_select 'span.icon', text: /Delete #{I18n.t('project')}/, count: 0
    assert_select 'span.disabled_icon', text: /Delete #{I18n.t('project')}/, count: 0
    assert_no_difference('Project.count') do
      delete :destroy, params: { id: project }
    end
    refute_nil flash[:error]
  end

  test 'can destroy project if it contains people' do
    project = Factory(:person).projects.first

    assert_equal 1,project.work_groups.count
    assert_equal 1, project.people.count
    assert_equal 1, project.group_memberships.count

    login_as(Factory(:admin))

    assert project.can_delete?

    assert_difference('Project.count', -1) do
      assert_difference('GroupMembership.count', -1) do
        assert_no_difference('Person.count') do
          assert_difference('WorkGroup.count',-1) do
            delete :destroy, params: { id: project }
          end
        end
      end
    end

  end
  
  def test_non_admin_should_not_manage_projects
    login_as(:aaron)
    get :manage, params: { id: Factory(:project) }
    assert_not_nil flash[:error]
  end

  test 'asset report with stuff in it can be accessed' do
    person = Factory(:person)
    publication = Factory(:publication, projects: person.projects)
    model = Factory(:model, policy: Factory(:public_policy), projects: person.projects, organism: Factory(:organism))

    model.save
    publication.associate(model)
    publication.save!
    project = person.projects.first

    assert_includes publication.projects, project
    login_as(person)
    get :asset_report, params: { id: project.id }

    assert_response :success
  end

  test 'asset report visible to project member' do
    person = Factory :person
    project = person.projects.first
    login_as(person.user)
    get :asset_report, params: { id: project.id }
    assert_response :success
  end

  test 'asset report not visible to non project member' do
    person = Factory :person
    project = person.projects.first
    other_person = Factory :person
    refute project.has_member?(other_person)
    login_as(other_person.user)
    get :asset_report, params: { id: project.id }
    assert_redirected_to project
    assert_not_nil flash[:error]
  end

  test 'asset report available to non project member if admin' do
    admin = Factory :admin
    project = Factory :project
    refute project.has_member?(admin)
    login_as(admin)
    get :asset_report, params: { id: project.id }
    assert_response :success
  end

  test 'asset report button shown to project members' do
    person = Factory :person
    project = person.projects.first

    login_as person.user
    get :show, params: { id: project.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', asset_report_project_path(project), text: 'Asset report'
    end
  end

  test 'asset report button not shown to anonymous users' do
    project = Factory :project

    logout
    get :show, params: { id: project.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', asset_report_project_path(project), text: 'Asset report', count: 0
    end
  end

  test 'asset report button not shown to none project members' do
    person = Factory :person
    project = person.projects.first
    other_person = Factory :person
    refute project.has_member?(other_person)

    login_as other_person.user
    get :show, params: { id: project.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', asset_report_project_path(project), text: 'Sharing report', count: 0
    end
  end

  test 'asset report button shown to admin that is not a project member' do
    admin = Factory(:admin)
    project = Factory(:project)
    refute project.has_member?(admin)
    login_as(admin)
    get :show, params: { id: project.id }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', asset_report_project_path(project), text: 'Asset report'
    end
  end

  test 'should show organise link for member' do
    p = Factory :person
    login_as p.user
    get :show, params: { id: p.projects.first }
    assert_response :success
    assert_select 'a[href=?]', project_folders_path(p.projects.first)
  end

  test 'should not show organise link for non member' do
    p = Factory :person
    proj = Factory :project
    login_as p.user
    get :show, params: { id: proj }
    assert_response :success
    assert_select 'a[href=?]', project_folders_path(p.projects.first), count: 0
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
    get :show, params: { id: projects(:three) }
    assert_response :success

    logout
    get :show, params: { id: projects(:three) }
    assert_response :success
  end

  test 'non-project member and non-login user can not edit project' do
    login_as(:registered_user_with_no_projects)
    get :show, params: { id: projects(:three) }
    assert_response :success
    assert_select 'a', text: /Edit Project/, count: 0
    assert_select 'a', text: /Manage Project/, count: 0

    logout
    get :show, params: { id: projects(:three) }
    assert_response :success
    assert_select 'a', text: /Edit Project/, count: 0
    assert_select 'a', text: /Manage Project/, count: 0
  end

  def test_user_project_administrator
    project_admin = Factory(:project_administrator)
    proj = project_admin.projects.first
    login_as(project_admin.user)
    get :show, params: { id: proj.id }
    assert_select 'a', text: /Manage #{I18n.t('project')}/, count: 1

    get :edit, params: { id: proj.id }
    assert_response :success

    put :update, params: { id: proj.id, project: { title: 'fish' } }
    proj = assigns(:project)
    assert_redirected_to proj
    assert_equal 'fish', proj.title
  end

  def test_user_cant_edit_project
    login_as(Factory(:user))
    get :show, params: { id: projects(:three) }
    assert_select 'a', text: /Edit #{I18n.t('project')}/, count: 0
    assert_select 'a', text: /Manage #{I18n.t('project')}/, count: 0

    get :edit, params: { id: projects(:three) }
    assert_response :redirect

    # TODO: Test for update
  end

  def test_admin_can_edit
    get :show, params: { id: projects(:one) }
    assert_select 'a', text: /Manage #{I18n.t('project')}/, count: 1

    get :edit, params: { id: projects(:one) }
    assert_response :success

    put :update, params: { id: projects(:three).id, project: { title: 'asd' } }

    assert_redirected_to project_path(assigns(:project))
  end

  test 'member can edit project details' do
    p = Factory(:person)
    login_as(p)

    get :show, params: { id: p.projects.first }
    assert_select 'a', text: /Edit #{I18n.t('project')}/, count: 1
    assert_select 'a', text: /Manage #{I18n.t('project')}/, count: 0

    get :edit, params: { id: p.projects.first }
    assert_response :success

    put :update, params: { id: p.projects.first.id, project: { title: 'asd' } }

    assert_redirected_to project_path(assigns(:project))
    assert_equal 'asd', assigns(:project).title
  end

  test 'normal member cannot edit protected attributes' do
    p = Factory(:person)
    login_as(p)

    get :show, params: { id: p.projects.first }
    assert_select 'a', text: /Edit #{I18n.t('project')}/, count: 1
    assert_select 'a', text: /Manage #{I18n.t('project')}/, count: 0

    get :edit, params: { id: p.projects.first }
    assert_response :success

    put :update, params: { id: p.projects.first.id, project: { title: 'asd', default_license: 'fish' } }

    assert_redirected_to project_path(assigns(:project))
    assert_equal 'asd', assigns(:project).title
    assert_not_equal 'fish', assigns(:project).default_license
  end

  test 'links have nofollow in sop tabs' do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    sop = Factory :sop, description: 'http://news.bbc.co.uk', project_ids: [project.id], contributor: user.person
    get :show, params: { id: project }
    assert_response :success

    assert_select 'div.list_item  div.list_item_desc' do
      assert_select 'a[rel=?]', 'nofollow', text: /news\.bbc\.co\.uk/, count: 1
    end
  end

  test 'links have nofollow in data_files tabs' do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    df = Factory :data_file, description: 'http://news.bbc.co.uk', project_ids: [project.id], contributor: user.person
    get :show, params: { id: project }
    assert_response :success

    assert_select 'div.list_item div.list_item_desc' do
      assert_select 'a[rel=?]', 'nofollow', text: /news\.bbc\.co\.uk/, count: 1
    end
  end

  test 'links have nofollow in model tabs' do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    model = Factory :model, description: 'http://news.bbc.co.uk', project_ids: [project.id], contributor: user.person
    get :show, params: { id: project }

    assert_select 'div.list_item  div.list_item_desc' do
      assert_select 'a[rel=?]', 'nofollow', text: /news\.bbc\.co\.uk/, count: 1
    end
  end

  test 'pals displayed in show page' do
    pal = Factory :pal, first_name: 'A', last_name: 'PAL'
    project = pal.projects.first
    get :show, params: { id: project }
    assert_select 'div.box_about_actor p.pals' do
      assert_select 'strong', text: 'SysMO-DB PALs:', count: 1
      assert_select 'a', count: 1
      assert_select 'a[href=?]', person_path(pal), text: 'A PAL', count: 1
    end
  end

  test 'asset_managers displayed in show page' do
    asset_manager = Factory(:asset_housekeeper)
    login_as asset_manager.user
    get :show, params: { id: asset_manager.projects.first }
    assert_select 'div.box_about_actor p.asset_housekeepers' do
      assert_select 'strong', text: 'Asset housekeepers:', count: 1
      assert_select 'a', count: 1
      assert_select 'a[href=?]', person_path(asset_manager), text: asset_manager.name, count: 1
    end
  end

  test 'project administrators displayed in show page' do
    project_administrator = Factory(:project_administrator)
    login_as project_administrator.user
    get :show, params: { id: project_administrator.projects.first }
    assert_select 'div.box_about_actor p.project_administrators' do
      assert_select 'strong', text: "#{I18n.t('project')} administrators:", count: 1
      assert_select 'a', count: 1
      assert_select 'a[href=?]', person_path(project_administrator), text: project_administrator.name, count: 1
    end
  end

  test 'gatekeepers displayed in show page' do
    gatekeeper = Factory(:asset_gatekeeper)
    login_as gatekeeper.user
    get :show, params: { id: gatekeeper.projects.first }
    assert_select 'div.box_about_actor p.asset_gatekeepers' do
      assert_select 'strong', text: I18n.t('asset_gatekeeper').pluralize+':', count: 1
      assert_select 'a', count: 1
      assert_select 'a[href=?]', person_path(gatekeeper), text: gatekeeper.name, count: 1
    end
  end

  test 'dont display the roles(except pals and administrators) for people who are not the members of this showed project' do
    project = Factory(:project)
    work_group = Factory(:work_group, project: project)

    asset_manager = Factory(:asset_housekeeper, group_memberships: [Factory(:group_membership, work_group: work_group)])
    project_administrator = Factory(:project_administrator, group_memberships: [Factory(:group_membership, work_group: work_group)])
    gatekeeper = Factory(:asset_gatekeeper, group_memberships: [Factory(:group_membership, work_group: work_group)])
    pal = Factory(:pal, group_memberships: [Factory(:group_membership, work_group: work_group)])

    a_person = Factory(:person)

    assert !a_person.projects.include?(project)

    login_as(a_person.user)
    get :show, params: { id: project }
    assert_select 'div.box_about_actor p' do
      assert_select 'strong', text: 'Asset housekeepers:', count: 0
      assert_select 'a[href=?]', person_path(asset_manager), text: asset_manager.name, count: 0


      assert_select 'strong', text: I18n.t('asset_gatekeeper').pluralize+':', count: 0
      assert_select 'a[href=?]', person_path(gatekeeper), text: gatekeeper.name, count: 0

      assert_select 'strong', text: 'SysMO-DB PALs:', count: 1
      assert_select 'a[href=?]', person_path(pal), text: pal.name, count: 1

      assert_select 'strong', text: 'Project administrators:', count: 1
      assert_select 'a[href=?]', person_path(project_administrator), text: project_administrator.name, count: 1
    end
  end

  test "get a person's projects" do
    person = Factory(:person)
    project = person.projects.first
    get :index, params: { person_id: person.id }
    assert_response :success
    projects = assigns(:projects)
    assert_equal [project], projects
    assert_equal person, assigns(:parent_resource)
    assert projects.count < Project.all.count
  end

  test 'no pals displayed for project with no pals' do
    get :show, params: { id: projects(:myexperiment_project) }
    assert_select 'div.box_about_actor p.pals' do
      assert_select 'strong', text: 'SysMO-DB PALs:', count: 1
      assert_select 'a', count: 0
      assert_select 'span.none_text', text: "No PALs for this #{I18n.t('project')}", count: 1
    end
  end

  test 'no asset housekeepers displayed for project with no asset housekeepers' do
    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: work_group)])
    login_as person.user
    get :show, params: { id: project }
    assert_select 'div.box_about_actor p.asset_housekeepers' do
      assert_select 'strong', text: 'Asset housekeepers:', count: 1
      assert_select 'a', count: 0
      assert_select 'span.none_text', text: "No Asset housekeepers for this #{I18n.t('project')}", count: 1
    end
  end

  test 'no project administrator displayed for project with no project managers' do
    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: work_group)])
    login_as person.user
    get :show, params: { id: project }
    assert_select 'div.box_about_actor p.project_administrators' do
      assert_select 'strong', text: "#{I18n.t('project')} administrators:", count: 1
      assert_select 'a', count: 0
      assert_select 'span.none_text', text: "No #{I18n.t('project')} administrators for this #{I18n.t('project')}", count: 1
    end
  end

  test 'no gatekeepers displayed for project with no gatekeepers' do
    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: work_group)])
    login_as person.user
    get :show, params: { id: project }
    assert_select 'div.box_about_actor p.asset_gatekeepers' do
      assert_select 'strong', text: 'Asset gatekeepers:', count: 1
      assert_select 'a', count: 0
      assert_select 'span.none_text', text: "No Asset gatekeepers for this #{I18n.t('project')}", count: 1
    end
  end

  test 'non admin cannot administer secure project settings' do
    person = Factory(:person)
    login_as(person.user)
    get :edit, params: { id: person.projects.first }
    assert_response :success
    assert_select '#sharing_form', count: 0
  end

  test 'admin can administer project' do
    get :edit, params: { id: projects(:sysmo_project) }
    assert_response :success
    assert_select '#sharing_form', count: 1
  end

  test 'non admin has no option to administer project' do
    user = Factory :user
    assert_equal 1, user.person.projects.count
    project = user.person.projects.first
    login_as(user)
    get :show, params: { id: project }
    assert_select '#buttons' do
      assert_select 'a[href=?]', admin_members_project_path(project), count: 0
    end
  end

  test 'admin has option to administer project' do
    admin = Factory :admin
    assert_equal 1, admin.projects.count
    project = admin.projects.first
    login_as(admin.user)
    get :show, params: { id: project }
    assert_select '#buttons' do
      assert_select 'a[href=?]', admin_members_project_path(project), text: /Administer #{I18n.t('project')} members/, count: 1
    end
  end

  test 'changing default policy' do
    login_as(:quentin)

    person = people(:aaron_person)
    project = projects(:four)
    assert_nil project.default_policy_id # check theres no policy to begin with

    # Set up the sharing param to share with one person (aaron)
    sharing = {}
    sharing[:permissions_attributes] = {}
    sharing[:permissions_attributes]['1'] = { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::NO_ACCESS }
    sharing[:access_type] = Policy::VISIBLE

    put :update, params: { id: project.id, project: valid_project, policy_attributes: sharing }

    project = Project.find(project.id)
    assert_redirected_to project
    assert project.default_policy_id
    assert Permission.find_by_policy_id(project.default_policy).contributor_id == person.id
  end

  test 'changing default policy even if not site admin' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    login_as(project_administrator.user)

    person = Factory(:person)
    sharing = {}
    sharing[:permissions_attributes] = {}
    sharing[:permissions_attributes]['1'] = { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::NO_ACCESS }
    sharing[:access_type] = Policy::VISIBLE

    put :update, params: { id: project.id, project: valid_project, policy_attributes: sharing }

    project = Project.find(project.id)
    assert_redirected_to project
    assert project.default_policy_id
    assert Permission.find_by_policy_id(project.default_policy).contributor_id == person.id
  end

  test 'cannot changing default policy even if not project admin' do
    project_member = Factory(:person)
    project = project_member.projects.first
    login_as(project_member.user)

    assert project.default_policy.nil?

    person = Factory(:person)
    sharing = {}
    sharing[:permissions_attributes] = {}
    sharing[:permissions_attributes]['1'] = { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::NO_ACCESS }
    sharing[:access_type] = Policy::VISIBLE

    assert_no_difference('Permission.count') do
      put :update, params: { id: project.id, project: valid_project, policy_attributes: sharing }
    end

    project = Project.find(project.id)
    assert_redirected_to project
    assert project.default_policy.nil?
  end

  test 'project administrator can administer their projects' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    login_as(project_administrator.user)

    get :show, params: { id: project }
    assert_response :success
    assert_select 'a[href=?]', admin_members_project_path(project), text: /Administer #{I18n.t('project')} members/, count: 1

    get :edit, params: { id: project }
    assert_response :success

    put :update, params: { id: project, project: { title: 'banana' } }
    assert_redirected_to project
    assert_equal 'banana', project.reload.title
  end

  test 'project administrator can not administer the projects that they are not in' do
    project_administrator = Factory(:project_administrator)
    a_project = Factory(:project)
    assert !(project_administrator.projects.include? a_project)
    login_as(project_administrator.user)

    get :show, params: { id: a_project }
    assert_response :success
    assert_select 'a', text: /Project administration/, count: 0

    get :edit, params: { id: a_project }
    assert_redirected_to :root
    assert_not_nil flash[:error]

    put :update, params: { id: a_project, project: { title: 'banana' } }
    assert_redirected_to :root
    assert_not_nil flash[:error]
    assert_not_equal 'banana', a_project.reload.title
  end

  test 'project administrator can administer sharing policy' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    disable_authorization_checks { project.default_policy = Policy.default; project.save }

    policy = project.reload.default_policy

    assert_not_equal policy.access_type, Policy::VISIBLE

    login_as(project_administrator.user)
    put :update, params: { id: project.id, project: valid_project, policy_attributes: { access_type: Policy::VISIBLE } }
    project.reload
    assert_redirected_to project
    assert_equal project.default_policy.access_type, Policy::VISIBLE
  end

  test 'project administrator can not administer jerm detail' do
    with_config_value :jerm_enabled, true do
      project_administrator = Factory(:project_administrator)
      project = project_administrator.projects.first
      assert_nil project.site_root_uri
      assert_nil project.site_username
      assert_nil project.site_password

      login_as(project_administrator.user)
      put :update, params: { id: project.id, project: { site_root_uri: 'test', site_username: 'test', site_password: 'test' } }

      project.reload
      assert_redirected_to project
      assert_nil project.site_root_uri
      assert_nil project.site_username
      assert_nil project.site_password
    end
  end

  test 'email job created when edited by a member' do
    person = Factory(:person)
    project = person.projects.first
    login_as(person)

    assert_enqueued_with(job: ProjectChangedEmailJob) do
      post :update, params: { id: project, project: { description: 'sdfkuhsdfkhsdfkhsdf' } }
    end
  end

  test 'no email job created when edited by an admin' do
    person = Factory(:admin)
    project = person.projects.first
    login_as(person)

    assert_no_enqueued_jobs(only: ProjectChangedEmailJob) do
      post :update, params: { id: project, project: { description: 'sdfkuhsdfkhsdfkhsdf' } }
    end
  end

  test 'no email job created when edited by an project administrator' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)
    assert_no_enqueued_jobs(only: ProjectChangedEmailJob) do
      post :update, params: { id: project, project: { description: 'sdfkuhsdfkhsdfkhsdf' } }
    end
  end

  test 'projects belonging to an institution through nested route' do
    assert_routing 'institutions/3/projects', controller: 'projects', action: 'index', institution_id: '3'

    project = Factory(:project)
    institution = Factory(:institution)
    Factory(:work_group, project: project, institution: institution)
    project2 = Factory(:project)
    Factory(:work_group, project: project2, institution: Factory(:institution))

    get :index, params: { institution_id: institution.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(project), text: project.title
      assert_select 'a[href=?]', project_path(project2), text: project2.title, count: 0
    end
  end

  test 'projects filtered by data file using nested routes' do
    assert_routing 'data_files/3/projects', controller: 'projects', action: 'index', data_file_id: '3'
    df1 = Factory(:data_file, policy: Factory(:public_policy))
    df2 = Factory(:data_file, policy: Factory(:public_policy))
    refute_equal df1.projects, df2.projects
    get :index, params: { data_file_id: df1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(df1.projects.first), text: df1.projects.first.title
      assert_select 'a[href=?]', project_path(df2.projects.first), text: df2.projects.first.title, count: 0
    end
  end

  test 'projects filtered by models using nested routes' do
    assert_routing 'models/3/projects', controller: 'projects', action: 'index', model_id: '3'
    model1 = Factory(:model, policy: Factory(:public_policy))
    model2 = Factory(:model, policy: Factory(:public_policy))
    refute_equal model1.projects, model2.projects
    get :index, params: { model_id: model1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(model1.projects.first), text: model1.projects.first.title
      assert_select 'a[href=?]', project_path(model2.projects.first), text: model2.projects.first.title, count: 0
    end
  end

  test 'projects filtered by sops using nested routes' do
    assert_routing 'sops/3/projects', controller: 'projects', action: 'index', sop_id: '3'
    sop1 = Factory(:sop, policy: Factory(:public_policy))
    sop2 = Factory(:sop, policy: Factory(:public_policy))
    refute_equal sop1.projects, sop2.projects
    get :index, params: { sop_id: sop1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(sop1.projects.first), text: sop1.projects.first.title
      assert_select 'a[href=?]', project_path(sop2.projects.first), text: sop2.projects.first.title, count: 0
    end
  end

  test 'projects filtered by publication using nested routes' do
    assert_routing 'publications/3/projects', controller: 'projects', action: 'index', publication_id: '3'
    pub1 = Factory(:publication)
    pub2 = Factory(:publication)
    refute_equal pub1.projects, pub2.projects
    get :index, params: { publication_id: pub1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(pub1.projects.first), text: pub1.projects.first.title
      assert_select 'a[href=?]', project_path(pub2.projects.first), text: pub2.projects.first.title, count: 0
    end
  end

  test 'projects filtered by events using nested routes' do
    assert_routing 'events/3/projects', controller: 'projects', action: 'index', event_id: '3'
    event1 = Factory(:event)
    event2 = Factory(:event)
    refute_equal event1.projects, event2.projects
    get :index, params: { event_id: event1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(event1.projects.first), text: event1.projects.first.title
      assert_select 'a[href=?]', project_path(event2.projects.first), text: event2.projects.first.title, count: 0
    end
  end

  test 'projects filtered by strain using nested routes' do
    assert_routing 'strains/2/projects', controller: 'projects', action: 'index', strain_id: '2'
    strain1 = Factory(:strain, policy: Factory(:public_policy))
    strain2 = Factory(:strain, policy: Factory(:public_policy))
    project1 = strain1.projects.first
    project2 = strain2.projects.first
    refute_empty strain1.projects
    refute_empty strain2.projects
    refute_equal project1, project2

    assert_includes project1.strains, strain1
    assert_includes project2.strains, strain2

    get :index, params: { strain_id: strain1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', project_path(strain1.projects.first), text: strain1.projects.first.title
      assert_select 'a[href=?]', project_path(strain2.projects.first), text: strain2.projects.first.title, count: 0
    end
  end

  test 'programme shown in list' do
    prog = Factory(:programme, projects: [Factory(:project), Factory(:project)])
    get :index
    assert_select 'p.list_item_attribute' do
      assert_select 'b', text: /#{I18n.t('programme')}/i
      assert_select 'a[href=?]', programme_path(prog), text: prog.title, count: 2
    end
  end

  test 'programme not shown in list when disabled' do
    prog = Factory(:programme, projects: [Factory(:project), Factory(:project)])
    with_config_value :programmes_enabled, false do
      get :index
      assert_select 'p.list_item_attribute' do
        assert_select 'b', text: /#{I18n.t('programme')}/i, count: 0
        assert_select 'a[href=?]', programme_path(prog), text: prog.title, count: 0
      end
    end
  end

  test 'programme shown' do
    prog = Factory(:programme, projects: [Factory(:project), Factory(:project)])
    get :show, params: { id: prog.projects.first }
    assert_select 'strong', text: /#{I18n.t('programme')}/i, count: 1
    assert_select '.box_about_actor a[href=?]', programme_path(prog), text: prog.title, count: 1
    assert_select '.related-items a[href=?]', programme_path(prog), text: prog.title, count: 1
  end

  test 'programme not shown when disabled' do
    prog = Factory(:programme, projects: [Factory(:project), Factory(:project)])
    with_config_value :programmes_enabled, false do
      get :show, params: { id: prog.projects.first }
      assert_select 'strong', text: /#{I18n.t('programme')}/i, count: 0
      assert_select 'a[href=?]', programme_path(prog), text: prog.title, count: 0
    end
  end

  test 'get as json' do
    proj = Factory(:project, title: 'fishing project', description: 'investigating fishing')
    get :show, params: { id: proj, format: 'json' }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal 'fishing project', json['data']['attributes']['title']
    assert_equal 'investigating fishing', json['data']['attributes']['description']
  end

  test 'admin members available to admin' do
    login_as(Factory(:admin))
    p = Factory(:project)
    get :admin_members, params: { id: p }
    assert_response :success
  end

  test 'admin_members available to project administrator' do
    person = Factory(:project_administrator)
    login_as(person)
    project = person.projects.first
    get :admin_members, params: { id: project }
    assert_response :success
  end

  test 'admin members not available to normal person' do
    login_as(Factory(:person))
    p = Factory(:project)
    get :admin_members, params: { id: p }
    assert_redirected_to :root
  end

  test 'update members' do
    login_as(Factory(:admin))
    project = Factory(:project)
    wg = Factory(:work_group, project: project)
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])
    group_membership2 = Factory(:group_membership, work_group: wg)
    person2 = Factory(:person, group_memberships: [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    new_person3 = Factory(:person)

    assert_difference('GroupMembership.count',1) do # 2 deleted, 3 added
      assert_no_difference('WorkGroup.count') do # 1 empty group will be deleted, 1 will be added
        assert_enqueued_emails(3) do
          post :update_members, params: { id: project, group_memberships_to_remove: [group_membership.id, group_membership2.id], people_and_institutions_to_add: [{ 'person_id' => new_person.id, 'institution_id' => new_institution.id }.to_json,
                                                { 'person_id' => new_person2.id, 'institution_id' => new_institution.id }.to_json,
                                                { 'person_id' => new_person3.id, 'institution_id' => new_institution.id }.to_json] }
        end
      end
    end

    assert_redirected_to project_path(project)
    assert_nil flash[:error]
    refute_nil flash[:notice]

    assert_includes project.institutions, new_institution
    assert_includes project.people, new_person
    assert_includes project.people, new_person2

    person.reload
    new_person.reload
    new_person2.reload

    refute_includes person.projects, project
    refute_includes person2.projects, project
    assert_includes new_person.projects, project
    assert_includes new_person2.projects, project
    assert_includes new_person.institutions, new_institution
    assert_includes new_person2.institutions, new_institution

    assert_includes new_person.project_subscriptions.collect(&:project), project
    assert_includes new_person2.project_subscriptions.collect(&:project), project

    refute_includes person.project_subscriptions.collect(&:project), project
    refute_includes person2.project_subscriptions.collect(&:project), project
  end

  test 'update members_json' do
    login_as(Factory(:admin))
    project = Factory(:project)
    wg = Factory(:work_group, project: project)
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])
    group_membership2 = Factory(:group_membership, work_group: wg)
    person2 = Factory(:person, group_memberships: [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    new_person3 = Factory(:person)

    put :update, params: { id:project.id, project: { members: [{ 'person_id' => "#{new_person.id}", 'institution_id' => "#{new_institution.id}" },
                                                                          { 'person_id' => "#{new_person2.id}", 'institution_id' => "#{new_institution.id}" },
                                                                          { 'person_id' => "#{new_person3.id}", 'institution_id' => "#{new_institution.id}" }] } }

    assert_redirected_to project_path(project)
    assert_nil flash[:error]

    assert_includes project.institutions, new_institution
    assert_includes project.people, new_person
    assert_includes project.people, new_person2

    person.reload
    new_person.reload
    new_person2.reload

    refute_includes person.projects, project
    refute_includes person2.projects, project
    assert_includes new_person.projects, project
    assert_includes new_person2.projects, project
    assert_includes new_person.institutions, new_institution
    assert_includes new_person2.institutions, new_institution

    assert_includes new_person.project_subscriptions.collect(&:project), project
    assert_includes new_person2.project_subscriptions.collect(&:project), project

    refute_includes person.project_subscriptions.collect(&:project), project
    refute_includes person2.project_subscriptions.collect(&:project), project
  end

  test 'update members as project administrator' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    wg = Factory(:work_group, project: project)
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])
    group_membership2 = Factory(:group_membership, work_group: wg)
    person2 = Factory(:person, group_memberships: [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    assert_no_difference('GroupMembership.count') do # 2 deleted, 2 added
      assert_no_difference('WorkGroup.count') do # 1 empty group will be deleted, 1 will be added
        post :update_members, params: { id: project, group_memberships_to_remove: [group_membership.id, group_membership2.id], people_and_institutions_to_add: [{ 'person_id' => new_person.id, 'institution_id' => new_institution.id }.to_json, { 'person_id' => new_person2.id, 'institution_id' => new_institution.id }.to_json] }
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

    refute_includes person.projects, project
    refute_includes person2.projects, project
    assert_includes new_person.projects, project
    assert_includes new_person2.projects, project
    assert_includes new_person.institutions, new_institution
    assert_includes new_person2.institutions, new_institution
  end

  test 'can flag and unflag members as leaving as project administrator' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    wg = Factory(:work_group, project: project)
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])
    former_group_membership = Factory(:group_membership, time_left_at: 10.days.ago, work_group: wg, has_left: true)
    former_person = Factory(:person, group_memberships: [former_group_membership])
    assert_no_enqueued_jobs only: ProjectLeavingJob do
      assert_no_difference('GroupMembership.count') do
        post :update_members, params: { id: project, memberships_to_flag: { group_membership.id.to_s => { time_left_at: 1.day.ago },
                                    former_group_membership.id.to_s => { time_left_at: '' } } }
        assert_redirected_to project_path(project)
        assert_nil flash[:error]
        refute_nil flash[:notice]
      end
    end

    assert group_membership.reload.has_left
    refute former_group_membership.reload.has_left
    refute former_group_membership.reload[:has_left]
  end

  test 'cannot flag members of other projects as leaving' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    wg = Factory(:work_group, project: Factory(:project))
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])

    assert !group_membership.reload.has_left
    assert project != wg.project

    post :update_members, params: { id: project, memberships_to_flag: { group_membership.id.to_s => { time_left_at: 1.day.ago } } }

    assert_redirected_to project_path(project)
    assert_nil flash[:error]
    refute_nil flash[:notice]
    assert !group_membership.reload.has_left
  end

  test 'project administrator can access admin member roles' do
    pa = Factory(:project_administrator)
    login_as(pa)
    project = pa.projects.first
    get :admin_member_roles, params: { id: project }
    assert_response :success
  end

  test 'admin can access admin member roles' do
    pa = Factory(:admin)
    login_as(pa)
    project = pa.projects.first
    get :admin_member_roles, params: { id: project }
    assert_response :success
  end

  test 'normal user cannot access admin member roles' do
    pa = Factory(:person)
    login_as(pa)
    project = pa.projects.first
    get :admin_member_roles, params: { id: project }
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'update member admin roles' do
    pa = Factory(:programme_administrator)
    login_as(pa)
    project = pa.projects.first
    person = Factory(:person)
    person.add_to_project_and_institution(project, Factory(:institution))
    person.save!

    person2 = Factory(:person)
    person2.add_to_project_and_institution(project, Factory(:institution))
    person2.save!
    person2.reload

    assert_equal [pa, person, person2].sort, project.people.sort
    refute person.is_asset_gatekeeper?(project)
    refute person.is_asset_housekeeper?(project)
    refute person.is_project_administrator?(project)
    refute person.is_pal?(project)
    refute person2.is_asset_gatekeeper?(project)
    refute person2.is_asset_housekeeper?(project)
    refute person2.is_project_administrator?(project)
    refute person2.is_pal?(project)

    ids = "#{person.id},#{person2.id}"

    post :update_members, params: { id: project, project: { project_administrator_ids: ids, asset_gatekeeper_ids: ids, asset_housekeeper_ids: ids, pal_ids: ids } }

    assert_redirected_to project_path(project)
    assert_nil flash[:error]
    refute_nil flash[:notice]

    person.reload
    person2.reload
    assert_equal [pa, person, person2].sort, project.people.sort

    assert person.is_asset_gatekeeper?(project)
    assert person.is_asset_housekeeper?(project)
    assert person.is_project_administrator?(project)
    assert person.is_pal?(project)
    assert person2.is_asset_gatekeeper?(project)
    assert person2.is_asset_housekeeper?(project)
    assert person2.is_project_administrator?(project)
    assert person2.is_pal?(project)
  end

  test 'person who cannot administer project cannot update members' do
    login_as(Factory(:person))
    project = Factory(:project)
    wg = Factory(:work_group, project: project)
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])
    group_membership2 = Factory(:group_membership, work_group: wg)
    person2 = Factory(:person, group_memberships: [group_membership2])
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    assert_no_difference('GroupMembership.count') do
      assert_no_difference('WorkGroup.count') do
        post :update_members, params: { id: project, group_memberships_to_remove: [group_membership.id, group_membership2.id], people_and_institutions_to_add: [{ 'person_id' => new_person.id, 'institution_id' => new_institution.id }.to_json, { 'person_id' => new_person2.id, 'institution_id' => new_institution.id }.to_json] }
        assert_redirected_to :root
        refute_nil flash[:error]
      end
    end

    person.reload
    new_person.reload
    new_person2.reload

    assert_includes person.projects, project
    assert_includes person2.projects, project
    refute_includes new_person.projects, project
    refute_includes new_person2.projects, project
    refute_includes new_person.institutions, new_institution
    refute_includes new_person2.institutions, new_institution
  end

  test 'assigns current user and sets as administrator if requested on create' do
    person = Factory(:programme_administrator_not_in_project)
    institution = Factory(:institution)
    login_as(person)
    assert_difference('Project.count') do
      post :create, params: { project: { title: 'test2' }, default_member: { add_to_project: '1', institution_id: institution.id } }
    end

    assert project = assigns(:project)
    person.reload

    assert_includes person.projects, project
    assert_includes person.institutions, institution
    assert person.is_project_administrator?(project)
  end

  test 'does not assign current user and sets as administrator if not requested on create' do
    person = Factory(:programme_administrator_not_in_project)
    institution = Factory(:institution)
    login_as(person)
    assert_difference('Project.count') do
      post :create, params: { project: { title: 'test2' }, default_member: { add_to_project: '0', institution_id: institution.id } }
    end

    assert project = assigns(:project)
    person.reload

    refute_includes person.projects, project
    refute_includes person.institutions, institution
    refute person.is_project_administrator?(project)
  end

  test 'institution association removed after last member removed' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)

    institution1 = Factory(:institution)
    institution2 = Factory(:institution)
    wg1 = Factory(:work_group, project: project, institution: institution1)
    wg2 = Factory(:work_group, project: project, institution: institution2)
    group_membership1 = Factory(:group_membership, work_group: wg1)
    group_membership2 = Factory(:group_membership, work_group: wg2)
    person1 = Factory(:person, group_memberships: [group_membership1])
    person2 = Factory(:person, group_memberships: [group_membership2])

    assert_includes project.institutions, institution1
    assert_includes project.institutions, institution2

    assert_difference('GroupMembership.count', -1) do
      assert_difference('WorkGroup.count', -1) do
        post :update_members, params: { id: project, group_memberships_to_remove: [group_membership2.id], people_and_institutions_to_add: [] }
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
    wg1 = Factory(:work_group, project: project, institution: institution1)
    group_membership1 = Factory(:group_membership, work_group: wg1)
    group_membership2 = Factory(:group_membership, work_group: wg1)
    person1 = Factory(:person, group_memberships: [group_membership1])
    person2 = Factory(:person, group_memberships: [group_membership2])

    assert_includes project.institutions, institution1

    assert_difference('GroupMembership.count', -1) do
      assert_no_difference('WorkGroup.count') do
        post :update_members, params: { id: project, group_memberships_to_remove: [group_membership2.id], people_and_institutions_to_add: [] }
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
      get :show, params: { id: project.id }
    end

    log = ActivityLog.last
    assert_equal project, log.activity_loggable
    assert_equal 'show', log.action
    assert_equal person.user, log.culprit

    assert_difference('ActivityLog.count') do
      put :update, params: { id: project.id, project: { title: 'fishy project' } }
    end

    log = ActivityLog.last
    assert_equal project, log.activity_loggable
    assert_equal 'update', log.action
    assert_equal person.user, log.culprit
  end

  test 'can get storage usage' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    data_file = Factory(:data_file, project_ids: [project.id])
    size = data_file.content_blob.file_size
    assert size > 0

    login_as(project_administrator)
    get :storage_report, params: { id: project.id }
    assert_response :success
    assert_nil flash[:error]
    assert_select 'strong', text: number_to_human_size(size)
  end

  test 'non admin cannot get storage usage' do
    person = Factory(:person)
    project = person.projects.first

    login_as(person)
    get :storage_report, params: { id: project.id }
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'search route' do
    assert_generates '/projects/1/search', controller: 'search', action: 'index', project_id: '1'
    assert_routing '/projects/1/search', controller: 'search', action: 'index', project_id: '1'
  end

  test 'update to use default sharing policy' do
    person=Factory(:project_administrator)
    project=person.projects.first
    login_as(person)
    assert project.can_manage?
    refute project.use_default_policy
    refute project.default_policy

    put :update, params: { id:project.id, project: { use_default_policy:'1' }, policy_attributes: valid_sharing }

    project=assigns(:project)
    assert project.use_default_policy
    assert project.default_policy


  end

  test 'can remove members with project subscriptions' do
    proj_admin = Factory(:project_administrator)
    project = proj_admin.projects.first
    login_as(proj_admin)

    wg = Factory(:work_group, project: project)
    group_membership = Factory(:group_membership, work_group: wg)
    person = Factory(:person, group_memberships: [group_membership])

    data_file = Factory(:data_file, projects: [project], contributor: person,
                        policy: Factory(:policy, access_type: Policy::NO_ACCESS,
                                        permissions: [Factory(:permission,
                                                              contributor: project,
                                                              access_type: Policy::VISIBLE)]))
    refute data_file.can_delete?(proj_admin)
    refute person.can_delete?(proj_admin)
    subscription = Factory(:subscription, subscribable: data_file, person: person, project_subscription: person.project_subscriptions.first)

    assert_difference('ProjectSubscription.count', -1) do
      assert_difference('Subscription.count', -1) do
          post :update_members, params: { id: project, group_memberships_to_remove: [group_membership.id], people_and_institutions_to_add: [] }
          assert_redirected_to project_path(project)
          assert_nil flash[:error]
          refute_nil flash[:notice]
      end
    end
  end

  test 'project administrator can not enable NeLS integration' do
    project_administrator = Factory(:project_administrator)
    project = project_administrator.projects.first
    assert_nil project.nels_enabled

    login_as(project_administrator.user)

    get :edit, params: { id: project.id }

    assert_select '#project_nels_enabled', count: 0

    put :update, params: { id: project.id, project: { nels_enabled: '1' } }

    project.reload
    assert_redirected_to project
    assert_nil project.nels_enabled
  end

  test 'site administrator can enable NeLS integration' do
    admin = Factory(:admin)
    project = Factory(:project)
    assert_nil project.nels_enabled

    login_as(admin.user)

    get :edit, params: { id: project.id }

    assert_select '#project_nels_enabled', count: 1
    assert_select '#project_nels_enabled[checked]', count: 0

    put :update, params: { id: project.id, project: { nels_enabled: '1' } }

    project.reload
    assert_redirected_to project
    assert_equal true, project.nels_enabled
  end

  test 'nels option hidden if not enabled seek wide' do
    admin = Factory(:admin)
    project = Factory(:project)

    login_as(admin.user)

    with_config_value(:nels_enabled,false) do
      get :edit, params: { id: project.id }
      assert_select 'div#nels_admin_section', count: 0
    end

    with_config_value(:nels_enabled,true) do
      get :edit, params: { id: project.id }
      assert_select 'div#nels_admin_section', count: 1
    end

  end

  test 'site administrator can disable NeLS integration' do
    admin = Factory(:admin)
    project = Factory(:project)
    project.nels_enabled = true
    assert_equal true, project.nels_enabled

    login_as(admin.user)

    get :edit, params: { id: project.id }

    assert_select '#project_nels_enabled', count: 1
    assert_select '#project_nels_enabled[checked]', count: 1

    put :update, params: { id: project.id, project: { nels_enabled: '0' } }

    project.reload
    assert_redirected_to project
    assert_equal false, project.nels_enabled
  end

  test 'start date overrides creation date in show page' do
    p = Factory(:project,start_date:nil, end_date:nil)

    get :show, params: { id:p.id }
    assert_select "p strong",text:'Project created:',count:1
    assert_select "p strong",text:'Project start date:',count:0
    assert_select "p strong",text:'Project end date:',count:0

    p = Factory(:project,start_date:DateTime.now, end_date:DateTime.now + 1.day)

    get :show, params: { id:p.id }
    assert_select "p strong",text:'Project created:',count:0
    assert_select "p strong",text:'Project start date:',count:1
    assert_select "p strong",text:'Project end date:',count:1

    # end date hidden if not set
    p = Factory(:project,start_date:DateTime.now, end_date:nil)

    get :show, params: { id:p.id }
    assert_select "p strong",text:'Project created:',count:0
    assert_select "p strong",text:'Project start date:',count:1
    assert_select "p strong",text:'Project end date:',count:0
  end

  test 'can request institutions' do
    project = Factory(:project)
    institution = Factory(:institution)
    member = Factory(:person, project: project, institution: institution)
    unrelated_institution = Factory(:institution)

    get :request_institutions, xhr: true, params: { id: project.id }

    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 200, res['status']

    list = res['institution_list']

    # The institution list is an array of arrays,
    # [0] institution title
    # [1] institution ID
    # [2] work group ID
    assert list.any? { |item| item[1] == institution.id }
    refute list.any? { |item| item[1] == unrelated_institution.id }
  end

  test 'cannot request institutions of non-existent project' do
    get :request_institutions, xhr: true, params: { id: Project.maximum(:id) + 100 }

    res = JSON.parse(response.body)

    assert_equal 404, res['status']
  end

  test "show New Project button if user can create them" do
    person = Factory(:admin)
    login_as(person)
    assert Project.can_create?

    get :index

    assert_response :success
    assert_select 'a.btn', text: 'New Project'
  end

  test "do not show New Project button if user cannot create them" do
    person = Factory(:person)
    login_as(person)
    refute Project.can_create?

    get :index

    assert_response :success
    assert_select 'a.btn', text: 'New Project', count: 0
  end

  test 'guided_join' do
    person = Factory(:person_not_in_project)
    login_as(person)
    get :guided_join
    assert_response :success
  end

  test 'guided join with project' do
    project = Factory(:project_administrator).projects.first
    person = Factory(:person)

    login_as(person)

    get :guided_join, params: { id: project.id }
    assert_response :success
    assert_select 'input#projects', value: project.id
  end

  test 'invalid guided join' do
    #already a member
    person = Factory(:project_administrator)
    project = person.projects.first
    refute_nil project

    login_as(person)

    get :guided_join, params:{id:project.id}
    assert_redirected_to project
    assert flash[:error]

    project = Factory(:project_administrator).projects.first

    # already requested
    ProjectMembershipMessageLog.log_request(sender:person, project:project, institution:Factory(:institution))
    get :guided_join, params:{id:project.id}
    assert_redirected_to project
    assert flash[:error]

  end

  test 'guided_create' do
    prog = Factory(:programme)
    person = Factory(:person_not_in_project)
    login_as(person)
    with_config_value(:managed_programme_id, prog.id) do
      get :guided_create
    end
    assert_response :success
    assert_select 'input#managed_programme', count:1

  end

  test 'guided create with administered programmes' do
    person = Factory(:programme_administrator)
    managed_prog = Factory(:programme, title:'THE MANAGED ONE')
    person_prog = person.programmes.first
    another_prog = Factory(:programme)
    login_as(person)
    with_config_value(:managed_programme_id, managed_prog.id) do
      get :guided_create
    end
    assert_response :success
    assert_select 'input#managed_programme', count:0
    assert_select 'select#programme_id' do
      assert_select 'option',count:2
      assert_select 'option',value:managed_prog.id,text:managed_prog.title
      assert_select 'option',value:person_prog.id,text:person_prog.title
      assert_select 'option',value:another_prog.id,text:another_prog.title, count:0
    end
  end

  test 'guided create with administered programmes as admin' do
    person = Factory(:programme_administrator)
    managed_prog = Factory(:programme, title:'THE MANAGED ONE')
    person_prog = person.programmes.first
    another_prog = Factory(:programme)
    admin = Factory(:admin)
    admin_prog = Factory(:programme)
    admin.is_programme_administrator = true, admin_prog
    admin.save!
    login_as(admin)
    with_config_value(:managed_programme_id, managed_prog.id) do
      get :guided_create
    end
    assert_response :success
    assert_select 'input#managed_programme', count:0
    assert_select 'select#programme_id' do
      assert_select 'option',count:2      
      assert_select 'option',value:managed_prog.id,text:managed_prog.title
      assert_select 'option',value:admin_prog.id,text:admin_prog.title
      assert_select 'option',value:person_prog.id,text:person_prog.title, count:0
      assert_select 'option',value:another_prog.id,text:another_prog.title, count:0
    end
  end

  test 'request_join_project with known project and institution' do
    person = Factory(:person_not_in_project)
    project = Factory(:project_administrator).projects.first #project needs to have an admin
    institution = Factory(:institution)
    login_as(person)
    params = {
        projects: project.id.to_s,
        institution:{
            id:institution.id
        },
        comments: 'some comments'
    }
    assert_enqueued_emails(1) do
      assert_difference('ProjectMembershipMessageLog.count') do
        post :request_join, params: params
      end
    end

    assert_response :success
    assert flash[:notice]
    log = ProjectMembershipMessageLog.last
    details = log.parsed_details
    assert_equal 'some comments', details.comments
    assert_equal institution.title, details.institution.title
    assert_equal institution.id, details.institution.id

  end

  test 'request_join_project with known project and new institution' do
    person = Factory(:person_not_in_project)
    project = Factory(:project_administrator).projects.first #project needs to have an admin
    login_as(person)

    institution_params = {
        title:'fish',
        city:'Sheffield',
        country:'GB',
        web_page:'http://google.com'
    }
    params = {
        projects: project.id.to_s,
        institution: institution_params,
        comments: 'some comments'
    }

    assert_enqueued_emails(1) do
      assert_difference('ProjectMembershipMessageLog.count') do
        post :request_join, params: params
      end
    end

    assert_response :success
    assert flash[:notice]
    log = ProjectMembershipMessageLog.last

    details = log.parsed_details
    assert_equal 'some comments', details.comments
    assert_nil details.institution.id
    assert_equal 'GB', details.institution.country
    assert_equal 'Sheffield', details.institution.city
    assert_equal 'http://google.com', details.institution.web_page
  end

  test 'request join multiple projects' do
    person = Factory(:person_not_in_project)
    project1 = Factory(:project_administrator).projects.first #project needs to have an admin
    project2 = Factory(:project_administrator).projects.first
    login_as(person)

    institution_params = {
      title:'fish',
      city:'Sheffield',
      country:'GB',
      web_page:'http://google.com'
    }
    params = {
      projects: "#{project1.id},#{project2.id}",
      institution: institution_params,
      comments: 'some comments'
    }

    assert_enqueued_emails(2) do
      assert_difference('ProjectMembershipMessageLog.count', 2) do
        post :request_join, params: params
      end
    end

    assert_response :success
    assert flash[:notice]
    log = ProjectMembershipMessageLog.last
    details = log.parsed_details
    assert_equal project2, log.subject
    assert_equal 'some comments', details.comments
    assert_nil details.institution.id
    assert_equal 'GB', details.institution.country
    assert_equal 'Sheffield', details.institution.city
    assert_equal 'http://google.com', details.institution.web_page
  end

  test 'request create project with site managed programme' do
    Factory(:admin)
    person = Factory(:person_not_in_project)
    programme = Factory(:programme)

    prog_admin = Factory(:person)
    prog_admin.is_programme_administrator = true, programme
    prog_admin.save!
    another_prog_admin = Factory(:person)
    another_prog_admin.is_programme_administrator = true, programme
    another_prog_admin.save!
    programme.reload
    assert_equal 2, programme.programme_administrators.count

    institution = Factory(:institution)
    
    refute programme.programme_administrators.select(&:is_admin?).any?
    login_as(person)
    with_config_value(:managed_programme_id, programme.id) do
      params = {
          programme_id: programme.id,
          project: { title: 'The Project', description: 'description', web_page: 'web_page'},
          institution: { id: institution.id }
      }
      assert_enqueued_emails(2) do # programme admins, and instance admins
        assert_difference('ProjectCreationMessageLog.count') do
          post :request_create, params: params
        end
      end

      assert_response :success
      assert flash[:notice]
      log = ProjectCreationMessageLog.last
      details = log.parsed_details
      assert_equal institution.title, details.institution.title
      assert_equal institution.id, details.institution.id
      assert_equal institution.country, details.institution.country
      assert_equal programme.title, details.programme.title
      assert_equal programme.id, details.programme.id
      assert_equal 'description', details.project.description
      assert_equal 'The Project', details.project.title
    end
  end

  test 'request create project with own administered programme' do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    institution = Factory(:institution)
    login_as(person)
    with_config_value(:managed_programme_id, nil) do
      params = {
        programme_id: programme.id,
        project: { title: 'The Project',description:'description',web_page:'web_page'},
        institution: {id: institution.id}
      }
      assert_enqueued_emails(0) do
        assert_difference('ProjectCreationMessageLog.count',1) do
          post :request_create, params: params
        end
      end
      log = ProjectCreationMessageLog.last
      assert_redirected_to administer_create_project_request_projects_path(message_log_id:log.id)

      details = log.parsed_details
      assert_equal institution.title, details.institution.title
      assert_equal institution.id, details.institution.id
      assert_equal institution.country, details.institution.country
      assert_equal programme.title, details.programme.title
      assert_equal programme.id, details.programme.id

      assert_equal 'description', details.project.description
      assert_equal 'The Project', details.project.title
    end
  end

  test 'request create project with new programme and institution' do
    Factory(:admin)
    person = Factory(:person_not_in_project)
    programme = Factory(:programme)
    assert Person.admins.count > 1
    login_as(person)
    with_config_value(:managed_programme_id, programme.id) do
      params = {
          project: { title: 'The Project', description:'description', web_page:'web_page'},
          institution: {title: 'the inst', web_page: 'the page', city: 'London', country: 'GB'},
          programme_id: '',
          programme: {title: 'the prog'}
      }
      assert_enqueued_emails(1) do
        assert_difference('ProjectCreationMessageLog.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('Project.count') do
              assert_no_difference('Programme.count') do
                post :request_create, params: params
              end
            end
          end
        end
      end

      assert_response :success
      assert flash[:notice]
      log = ProjectCreationMessageLog.last
      details = log.parsed_details

      assert_equal 'GB',details.institution.country
      assert_equal 'London',details.institution.city
      assert_equal 'the page',details.institution.web_page
      assert_equal 'the inst',details.institution.title
      assert_nil details.institution.id

      assert_equal 'description', details.project.description
      assert_equal 'The Project', details.project.title
      assert_nil  details.project.id

      assert_equal 'the prog',details.programme.title
      assert_nil details.programme.id
    end
  end

  test 'request create project without programmes' do
    person = Factory(:person_not_in_project)

    login_as(person)
    with_config_value(:programmes_enabled, false) do
      params = {
        project: { title: 'The Project',description:'description',web_page:'web_page'},
        institution: {title:'the inst',web_page:'the page',city:'London',country:'GB'}
      }
      assert_enqueued_emails(1) do
        assert_difference('ProjectCreationMessageLog.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('Project.count') do
              post :request_create, params: params
            end
          end
        end
      end

      assert_response :success
      assert flash[:notice]
      log = ProjectCreationMessageLog.last
      details = log.parsed_details

      assert_equal 'GB',details.institution.country
      assert_equal 'London',details.institution.city
      assert_equal 'the page',details.institution.web_page
      assert_equal 'the inst',details.institution.title
      assert_nil details.institution.id

      assert_equal 'description', details.project.description
      assert_equal 'The Project', details.project.title
      assert_nil  details.project.id

      assert_nil details.programme
    end
  end

  test 'administer join request' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)
    institution = Institution.new(title:'my institution')
    log = ProjectMembershipMessageLog.log_request(sender:Factory(:person), project:project, institution:institution, comments: 'some comments')
    get :administer_join_request, params:{id:project.id,message_log_id:log.id}
    assert_response :success
  end

  test 'administer join request with new institution that was since created' do
    person = Factory(:project_administrator)
    project = person.projects.first
    login_as(person)
    institution = Institution.new(title:'my institution')
    log = ProjectMembershipMessageLog.log_request(sender:Factory(:person), project:project, institution:institution, comments:'some comments')
    created_inst = Factory(:institution,title:'my institution')
    get :administer_join_request, params:{id:project.id,message_log_id:log.id}
    assert_response :success
    
    assert_select 'input#institution_title', count: 0
    assert_select 'input#institution_id', value: created_inst.id, count: 1
  end

  test 'admininster join request blocked for different admin' do
    person = Factory(:project_administrator)
    another_admin = Factory(:project_administrator)
    project = person.projects.first
    login_as(another_admin)
    institution = Institution.new(title:'my institution')
    log = ProjectMembershipMessageLog.log_request(sender:Factory(:person), project:project, institution:institution, comments:'some comments')
    get :administer_join_request, params:{id:project.id,message_log_id:log.id}
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'respond join request accept existing institution' do
    person = Factory(:project_administrator)
    login_as(person)
    project = person.projects.first
    institution = Factory(:institution)
    sender = Factory(:person)
    log = ProjectMembershipMessageLog.log_request(sender:sender, project:project, institution:institution, comments:'some comments')

    params = {
        message_log_id: log.id,
        accept_request: '1',
        institution:{id:institution.id},
        id:project.id
    }

    assert_enqueued_emails(1) do
      assert_no_difference('Institution.count') do
        assert_difference('GroupMembership.count') do
          post :respond_join_request, params:params
        end
      end
    end

    assert_redirected_to(project_path(project))
    assert_equal "Request accepted and #{log.sender.name} added to Project and notified",flash[:notice]
    project.reload
    assert_includes project.people, sender
    assert_includes project.institutions, institution

    log.reload
    assert log.responded?
    assert_equal 'Accepted',log.response
  end

  test 'respond join request blocked another admin' do
    person = Factory(:project_administrator)
    another_admin = Factory(:programme_administrator)
    login_as(another_admin)
    project = person.projects.first
    institution = Factory(:institution)
    sender = Factory(:person)
    log = ProjectMembershipMessageLog.log_request(sender:sender, project:project, institution:institution, comments:'some comments')

    params = {
        message_log_id: log.id,
        accept_request: '1',
        institution:{id:institution.id},
        id:project.id
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Institution.count') do
        assert_no_difference('GroupMembership.count') do
          post :respond_join_request, params:params
        end
      end
    end

    assert_redirected_to :root
    refute_nil flash[:error]

    log.reload
    refute log.responded?
  end

  test 'respond join request accept new institution' do
    person = Factory(:project_administrator)
    project = person.projects.first
    sender = Factory(:person)
    institution = Institution.new({
                                      title:'institution',
                                   country:'DE'
                                  })
    log = ProjectMembershipMessageLog.log_request(sender:sender, project:project, institution:institution, comments:'some comments')

    params = {
        message_log_id: log.id,
        accept_request: '1',
        institution:{
                     title:'institution',
                     country:'FR' # admin may have corrected this from DE
        },
        id:project.id
    }

    assert_enqueued_emails(1) do
      assert_difference('Institution.count') do
        assert_difference('GroupMembership.count') do
          post :respond_join_request, params:params
        end
      end
    end

    assert_redirected_to(project_path(project))
    assert_equal "Request accepted and #{log.sender.name} added to Project and notified",flash[:notice]
    project.reload
    institution = Institution.last
    assert_equal 'institution',institution.title
    assert_equal 'FR',institution.country
    assert_includes project.people, sender
    assert_includes project.institutions, institution

    log.reload
    assert log.responded?
    assert_equal 'Accepted',log.response
  end

  test 'respond join with new invalid institution' do
    person = Factory(:project_administrator)
    project = person.projects.first
    sender = Factory(:person)
    institution = Institution.new({
                                      title:'institution',
                                      country:'DE'
                                  })
    log = ProjectMembershipMessageLog.log_request(sender:sender, project:project, institution:institution, comments:'some comments')

    params = {
        message_log_id: log.id,
        accept_request: '1',
        institution:{
            title:'',
        },
        id:project.id
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Institution.count') do
        assert_no_difference('GroupMembership.count') do
          post :respond_join_request, params:params
        end
      end
    end

    assert_equal "The Institution is invalid, Title can't be blank",flash[:error]
    project.reload
    refute_includes project.people, sender

    log.reload
    refute log.responded?
  end

  test 'respond join request rejected' do
    person = Factory(:project_administrator)
    project = person.projects.first
    institution = Factory(:institution)
    sender = Factory(:person)
    log = ProjectMembershipMessageLog.log_request(sender:sender, project:project, institution:institution, comments:'some comments')

    params = {
        message_log_id: log.id,
        reject_details: 'bad request',
        institution:{id:institution.id},
        id:project.id
    }

    assert_enqueued_emails(1) do
      assert_no_difference('Institution.count') do
        assert_no_difference('GroupMembership.count') do
          post :respond_join_request, params:params
        end
      end
    end

    assert_redirected_to(project_path(project))
    assert_equal "Request rejected and #{log.sender.name} has been notified",flash[:notice]
    project.reload
    refute_includes project.people, sender
    refute_includes project.institutions, institution

    log.reload
    assert log.responded?
    assert_equal 'bad request',log.response
  end

  test 'administer create request project with new programme and institution' do
    person = Factory(:admin)
    login_as(person)
    project = Project.new(title:'new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new(title:'my institution')
    log = ProjectCreationMessageLog.log_request(sender:Factory(:person), programme:programme, project:project, institution:institution)
    get :administer_create_project_request, params:{message_log_id:log.id}
    assert_response :success
  end

  test 'administer create request project with institution already created' do
    # when a new institution when requested, but it has then been created before the request is handled 
    person = Factory(:admin)
    login_as(person)
    project = Project.new(title:'new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new(title:'my institution')
    log = ProjectCreationMessageLog.log_request(sender:Factory(:person), programme:programme, project:project, institution:institution)
    created_inst = Factory(:institution,title:'my institution')
    get :administer_create_project_request, params:{message_log_id:log.id}
    assert_response :success

    assert_select 'input#institution_title', count: 0
    assert_select 'input#institution_id', value: created_inst.id, count: 1
  end

  test 'admininister create request can be accessed by programme admin' do
    person = Factory(:programme_administrator)
    login_as(person)
    project = Project.new(title:'new project')
    programme = person.programmes.first
    institution = Institution.new(title:'my institution')
    log = ProjectCreationMessageLog.log_request(sender:Factory(:person), programme:programme, project:project, institution:institution)
    get :administer_create_project_request, params:{message_log_id:log.id}
    assert_response :success

    another_person = Factory(:programme_administrator)
    login_as(another_person)
    get :administer_create_project_request, params:{message_log_id:log.id}
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'admininister create request cannot be accessed by a different programme admin' do
    person = Factory(:programme_administrator)
    another_person = Factory(:programme_administrator)
    login_as(another_person)

    project = Project.new(title:'new project')
    programme = person.programmes.first
    institution = Institution.new(title:'my institution')
    log = ProjectCreationMessageLog.log_request(sender:Factory(:person), programme:programme, project:project, institution:institution)
    get :administer_create_project_request, params:{message_log_id:log.id}

    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'administer create request can be accessed by site admin for new programme' do
    person = Factory(:admin)
    login_as(person)
    project = Project.new(title:'new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new(title:'my institution')
    log = ProjectCreationMessageLog.log_request(sender:Factory(:person), programme:programme, project:project, institution:institution)
    get :administer_create_project_request, params:{message_log_id:log.id}
    assert_response :success
  end

  test 'administer create request cannot be accessed by none site admin for new programme' do
    person = Factory(:programme_administrator)
    login_as(person)
    project = Project.new(title:'new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new(title:'my institution')
    log = ProjectCreationMessageLog.log_request(sender:Factory(:person), programme:programme, project:project, institution:institution)
    get :administer_create_project_request, params:{message_log_id:log.id}

    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'respond create project request - new programme and institution' do
    person = Factory(:admin)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new({title:'institution', country:'DE'})
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        accept_request: '1',
        project:{
            title:'new project updated',
            web_page:'http://proj.org'
        },
        programme:{
            title:'new programme updated'
        },
        institution:{
            title:'new institution updated',
            city:'Paris',
            country:'FR'
        }
    }

    assert_enqueued_emails(1) do
      assert_difference('Programme.count') do
        assert_difference('Project.count') do
          assert_difference('Institution.count') do
            assert_difference('GroupMembership.count') do
              assert_difference('WorkGroup.count') do
                post :respond_create_project_request, params:params
              end              
            end
          end
        end
      end
    end

    project = Project.last
    programme = Programme.last
    institution = Institution.last
    requester.reload

    assert_redirected_to(project_path(project))
    assert_equal "Request accepted and #{log.sender.name} added to Project and notified",flash[:notice]

    assert_equal 'new project updated', project.title
    assert_equal 'new programme updated', programme.title
    assert_equal 'new institution updated', institution.title

    assert_includes programme.projects,project
    assert_includes project.people, requester
    assert_includes project.institutions, institution
    assert_includes programme.programme_administrators, requester
    assert_includes project.project_administrators, requester

    assert_equal WorkGroup.last, requester.work_groups.last
    assert_equal institution, requester.work_groups.last.institution
    assert_equal project, requester.work_groups.last.project

    log.reload
    assert log.responded?
    assert_equal 'Accepted',log.response

  end

  test 'respond create project request - new programme requires site admin' do
    person = Factory(:programme_administrator)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new({title:'institution', country:'DE'})
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        accept_request: '1',
        project:{
            title:'new project updated',
            web_page:'http://proj.org'
        },
        programme:{
            title:'new programme updated'
        },
        institution:{
            title:'new institution updated',
            city:'Paris',
            country:'FR'
        }
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Programme.count') do
        assert_no_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('GroupMembership.count') do
              post :respond_create_project_request, params:params
            end
          end
        end
      end
    end

    assert_redirected_to :root
    refute_nil flash[:error]

    log.reload
    refute log.responded?

  end

  test 'respond create project request - new programme and institution, project invalid' do
    person = Factory(:admin)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new({title:'institution', country:'DE'})
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        accept_request: '1',
        project:{
            title:''
        },
        programme:{
            title:'new programme updated'
        },
        institution:{
            title:'new institution updated',
            city:'Paris',
            country:'FR'
        }
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Programme.count') do
        assert_no_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('GroupMembership.count') do
              post :respond_create_project_request, params:params
            end
          end
        end
      end
    end

    assert_equal "The Project is invalid, Title can't be blank",flash[:error]

    log.reload
    refute log.responded?

  end


  test 'respond create project request - new programme and institution, programme and institution invalid' do
    person = Factory(:admin)
    duplicate_institution=Factory(:institution)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    programme = Programme.new(title:'new programme')
    institution = Institution.new({title:'institution', country:'DE'})
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        accept_request: '1',
        project:{
            title:'a valid project'
        },
        programme:{
            title:''
        },
        institution:{
            title:duplicate_institution.title,
            city:'Paris',
            country:'FR'
        }
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Programme.count') do
        assert_no_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('GroupMembership.count') do
              assert_no_difference('WorkGroup.count') do
                post :respond_create_project_request, params:params
              end              
            end
          end
        end
      end
    end

    assert_equal "The Programme is invalid, Title can't be blank<br/>The Institution is invalid, Title has already been taken",flash[:error]

    log.reload
    refute log.responded?
  end

  test 'respond create project request - existing programme and institution' do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    institution = Factory(:institution)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        accept_request: '1',
        project:{
            title:'new project',
            web_page:'http://proj.org'
        },
        programme:{
            id:programme.id
        },
        institution:{
            id:institution.id
        }
    }

    assert_enqueued_emails(1) do
      assert_no_difference('Programme.count') do
        assert_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_difference('GroupMembership.count') do
              post :respond_create_project_request, params:params
            end
          end
        end
      end
    end

    project = Project.last
    programme.reload

    assert_redirected_to(project_path(project))
    assert_equal "Request accepted and #{log.sender.name} added to Project and notified",flash[:notice]

    assert_includes programme.projects,project
    assert_includes project.people, requester
    assert_includes project.institutions, institution
    refute_includes programme.programme_administrators, requester
    assert_includes project.project_administrators, requester

    log.reload
    assert log.responded?
    assert_equal 'Accepted',log.response

  end

  test 'respond create project request as the same user' do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    institution = Factory(:institution)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    requester = person
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    assert log.sent_by_self?
    params = {
      message_log_id:log.id,
      accept_request: '1',
      project:{
        title:'new project',
        web_page:'http://proj.org'
      },
      programme:{
        id:programme.id
      },
      institution:{
        id:institution.id
      }
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Programme.count') do
        assert_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_difference('GroupMembership.count') do
              assert_difference('ProjectCreationMessageLog.count',-1) do
                post :respond_create_project_request, params:params
              end
            end
          end
        end
      end
    end

    project = Project.last
    programme.reload

    assert_redirected_to(project_path(project))
    assert_equal "Project created",flash[:notice]

    assert_includes programme.projects,project
    assert_includes project.people, requester
    assert_includes project.institutions, institution
    assert_includes project.project_administrators, requester

  end

  test 'respond create project request as the same user - cancel' do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    institution = Factory(:institution)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    requester = person
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    assert log.sent_by_self?
    params = {
      message_log_id:log.id,
      project:{
        title:'new project',
        web_page:'http://proj.org'
      },
      programme:{
        id:programme.id
      },
      institution:{
        id:institution.id
      }
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Programme.count') do
        assert_no_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('GroupMembership.count') do
              assert_difference('ProjectCreationMessageLog.count',-1) do
                post :respond_create_project_request, params:params
              end
            end
          end
        end
      end
    end

    assert_redirected_to :root
    assert_equal "Project creation cancelled",flash[:notice]
  end

  test 'respond create project request - existing programme need prog admin rights' do
    person = Factory(:programme_administrator)
    another_admin = Factory(:programme_administrator)
    programme = person.programmes.first
    institution = Factory(:institution)
    login_as(another_admin)
    project = Project.new(title:'new project',web_page:'my new project')
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        accept_request: '1',
        project:{
            title:'new project',
            web_page:'http://proj.org'
        },
        programme:{
            id:programme.id
        },
        institution:{
            id:institution.id
        }
    }

    assert_enqueued_emails(0) do
      assert_no_difference('Programme.count') do
        assert_no_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('GroupMembership.count') do
              post :respond_create_project_request, params:params
            end
          end
        end
      end
    end

    assert_redirected_to :root
    refute_nil flash[:error]

    log.reload
    refute log.responded?


  end

  test 'respond create project request - rejected' do
    person = Factory(:programme_administrator)
    programme = person.programmes.first
    institution = Factory(:institution)
    login_as(person)
    project = Project.new(title:'new project',web_page:'my new project')
    requester = Factory(:person)
    log = ProjectCreationMessageLog.log_request(sender:requester, programme:programme, project:project, institution:institution)
    params = {
        message_log_id:log.id,
        reject_details:'not very good',
        project:{
            title:'new project',
            web_page:'http://proj.org'
        },
        programme:{
            id:programme.id
        },
        institution:{
            id:institution.id
        }
    }

    assert_enqueued_emails(1) do
      assert_no_difference('Programme.count') do
        assert_no_difference('Project.count') do
          assert_no_difference('Institution.count') do
            assert_no_difference('GroupMembership.count') do
              post :respond_create_project_request, params:params
            end
          end
        end
      end
    end

    assert_redirected_to(root_path)
    assert_equal "Request rejected and #{log.sender.name} has been notified",flash[:notice]

    refute_includes programme.programme_administrators, requester

    log.reload
    assert log.responded?
    assert_equal 'not very good',log.response

  end

  test 'project join request' do
    person1 = Factory(:project_administrator)
    person2 = Factory(:project_administrator)
    project1 = person1.projects.first
    project2 = person2.projects.first

    requester1 = Factory(:person)
    requester2 = Factory(:person)
    requester3 = Factory(:person)

    log1 = ProjectMembershipMessageLog.log_request(sender:requester1, project:project1, institution:Factory(:institution))
    log2 = ProjectMembershipMessageLog.log_request(sender:requester2, project:project1, institution:Factory(:institution))
    log3 = ProjectMembershipMessageLog.log_request(sender:Factory(:person), project:project2, institution:Factory(:institution))

    logout
    get :project_join_requests
    assert_redirected_to login_path

    login_as(person1)

    get :project_join_requests
    assert_response :success

    assert_select 'h1',text:/2 pending project join/i

    assert_select 'table#project-join-requests' do
      assert_select 'tbody tr',count:2
      assert_select 'a[href=?]',person_path(requester1),text:requester1.title
      assert_select 'a[href=?]',person_path(requester2),text:requester2.title
      assert_select 'a[href=?]',administer_join_request_project_path(project1,message_log_id: log1.id)
      assert_select 'a[href=?]',administer_join_request_project_path(project1,message_log_id: log2.id)
      assert_select 'a[href=?]',project_path(project1),count:2

      assert_select 'a[href=?]',person_path(requester3),count:0
      assert_select 'a[href=?]',administer_join_request_project_path(project2,message_log_id: log3.id),count:0
      assert_select 'a[href=?]',project_path(project2),count:0
    end

    login_as(Factory(:person))
    get :project_join_requests
    assert_response :success

    assert_select 'h1',text:/0 pending project join/i

    assert_select 'table#project-join-requests' do
      assert_select 'tbody tr',count:0
      assert_select 'a[href=?]',person_path(requester1),text:requester1.title,count:0
      assert_select 'a[href=?]',person_path(requester2),text:requester2.title,count:0
      assert_select 'a[href=?]',administer_join_request_project_path(project1,message_log_id: log1.id),count:0
      assert_select 'a[href=?]',administer_join_request_project_path(project1,message_log_id: log2.id),count:0
      assert_select 'a[href=?]',project_path(project1),count:0

      assert_select 'a[href=?]',person_path(requester3),count:0
      assert_select 'a[href=?]',administer_join_request_project_path(project2,message_log_id: log3.id),count:0
      assert_select 'a[href=?]',project_path(project2),count:0
    end
  end

  test "project creation requests" do
    admin = Factory(:admin)
    prog_admin = Factory(:programme_administrator)
    programme = prog_admin.programmes.first
    person = Factory(:person)
    institution = Factory(:institution)
    project = Project.new(title: "new")

    log_existing_programme = ProjectCreationMessageLog.log_request(sender:person, programme:programme, project:project, institution:institution)
    log_new_programme = ProjectCreationMessageLog.log_request(sender:person, programme:Programme.new(title: "new"), project:project, institution:institution)

    # no user
    logout
    get :project_creation_requests
    assert_redirected_to :login
    refute_nil flash[:error]

    login_as(prog_admin)
    get :project_creation_requests
    assert_response :success

    assert_select "h1", text: /1 pending project creation/i
    assert_select "table#project-create-requests" do
      assert_select "tbody tr", count: 1
      assert_select "a[href=?]", person_path(person), text: person.title
      assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_existing_programme.id)
      assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_new_programme.id), count: 0
    end

    login_as(admin)
    get :project_creation_requests
    assert_response :success

    assert_select "h1", text: /1 pending project creation/i
    assert_select "table#project-create-requests" do
      assert_select "tbody tr", count: 1
      assert_select "a[href=?]", person_path(person), text: person.title
      assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_new_programme.id)
      assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_existing_programme.id), count: 0
    end

    with_config_value(:managed_programme_id, programme.id) do
      get :project_creation_requests
      assert_response :success

      assert_select "h1", text: /2 pending project creation/i
      assert_select "table#project-create-requests" do
        assert_select "tbody tr", count: 2
        assert_select "a[href=?]", person_path(person), text: person.title, count: 2
        assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_new_programme.id)
        assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_existing_programme.id)
      end
    end

    login_as(person)
    get :project_creation_requests
    assert_response :success

    assert_select "h1", text: /0 pending project creation/i
    assert_select "table#project-create-requests" do
      assert_select "tbody tr", count: 0
      assert_select "a[href=?]", person_path(person), text: person.title, count: 0
      assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_new_programme.id), count: 0
      assert_select "a[href=?]", administer_create_project_request_projects_path(message_log_id: log_existing_programme.id), count: 0
    end
  end

  test 'should create with discussion link' do
    person = Factory(:admin)
    login_as(person)
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Project.count') do
        post :create, params: { project: { title: 'test',
                                          discussion_links_attributes: [{url: "http://www.slack.com/"}]}}
      end
    end
    project = assigns(:project)
    assert_equal 'http://www.slack.com/', project.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, project.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    disc_link = Factory(:discussion_link)
    project = Factory(:project)
    project.discussion_links = [disc_link]
    get :show, params: { id: project }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = Factory(:admin)
    project = Factory(:project)
    login_as(person)
    assert_nil project.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: project.id, project: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to project_path(assigns(:project))
    assert_equal 'http://www.slack.com/', project.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = Factory(:admin)
    login_as(person)
    asset_link = Factory(:discussion_link)
    project = Factory(:project)
    project.discussion_links = [asset_link]
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: project.id, project: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to project_path(project = assigns(:project))
    assert_empty project.discussion_links
  end

    private

  def edit_max_object(project)
    for i in 1..5
      Factory(:person).add_to_project_and_institution(project, Factory(:institution))
    end
    project.default_policy = Factory(:private_policy)
    project.programme_id = (Factory(:programme)).id
    add_avatar_to_test_object(project)
  end

  def valid_project
    { title: "a title" }
  end  
  
end
