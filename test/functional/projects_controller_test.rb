require 'test_helper'
require 'libxml'

class ProjectsControllerTest < ActionController::TestCase

	include AuthenticatedTestHelper
	include RestTestCases
  include RdfTestCases

	fixtures :all

	def setup
		login_as(Factory(:admin).user)
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

	def test_should_create_project
		assert_difference('Project.count') do
			post :create, :project => {:name=>"test"}
		end

		assert_redirected_to project_path(assigns(:project))
	end

	def test_should_show_project
		get :show, :id => projects(:four)
		assert_response :success
	end

	def test_should_get_edit
		get :edit, :id => projects(:four)
		assert_response :success
	end

	def test_should_update_project
		put :update, :id => projects(:four), :project => valid_project
		assert_redirected_to project_path(assigns(:project))
	end

	def test_should_destroy_project
    project = projects(:four)
    get :show, :id => project
    assert_select "span.icon", :text => /Delete #{I18n.t('project')}/, :count => 1

		assert_difference('Project.count', -1) do
			delete :destroy, :id => project
		end

		assert_redirected_to projects_path
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
    assert_redirected_to project_path(project)
    assert_not_nil flash[:error]
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
    assert_select "ul.sectionIcons" do
      assert_select "a[href=?]",asset_report_project_path(project),:text=>"Asset report"
    end
  end

  test "asset report button not shown to anonymous users" do

    project = Factory :project

    logout
    get :show, :id=>project.id
    assert_response :success
    assert_select "ul.sectionIcons" do
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
    assert_select "ul.sectionIcons" do
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
    assert_select "ul.sectionIcons" do
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

	#Checks that the edit option is availabe to the user
	#with can_edit_project set and he belongs to that project
	def test_user_can_edit_project
		login_as(:can_edit)
		get :show, :id=>projects(:three)
		assert_select "a",:text=>/Edit #{I18n.t('project')}/,:count=>1

		get :edit, :id=>projects(:three)
		assert_response :success

		put :update, :id=>projects(:three).id,:project=>{}
		assert_redirected_to project_path(assigns(:project))
	end

	def test_user_project_manager
    pm = Factory(:project_manager)
    proj = pm.projects.first
		login_as(pm.user)
		get :show, :id=>proj.id
		assert_select "a",:text=>/Edit #{I18n.t('project')}/,:count=>1

		get :edit, :id=>proj.id
		assert_response :success

		put :update, :id=>proj.id,:project=>{:title=>"fish"}
    proj = assigns(:project)
		assert_redirected_to project_path(proj)
    assert_equal "fish",proj.title
	end

	def test_user_cant_edit_project
		login_as(:cant_edit)
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
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:count=>1
    end
	end

	test "links have nofollow in data_files tabs" do
    user = Factory :user
    project = user.person.projects.first
    login_as(user)
    df = Factory :data_file,:description=>"http://news.bbc.co.uk",:project_ids=>[project.id],:contributor=>user
    get :show,:id=>project
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
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:count=>1
    end
	end

	test "pals displayed in show page" do
    pal = Factory :pal,:first_name=>"A",:last_name=>"PAL"
    project = pal.projects.first
		get :show,:id=>project
		assert_select "div.box_about_actor p.pals" do
			assert_select "label",:text=>"SysMO-DB PALs:",:count=>1
			assert_select "a",:count=>1
			assert_select "a[href=?]",person_path(pal),:text=>"A PAL",:count=>1
		end
  end

  	test "asset_managers displayed in show page" do
      asset_manager = Factory(:asset_manager)
      login_as asset_manager.user
      get :show,:id=>asset_manager.projects.first
      assert_select "div.box_about_actor p.asset_managers" do
        assert_select "label",:text=>"Asset Managers:",:count=>1
        assert_select "a",:count=>1
        assert_select "a[href=?]",person_path(asset_manager),:text=>asset_manager.name,:count=>1
      end
    end

  	test "project_managers displayed in show page" do
		project_manager = Factory(:project_manager)
    login_as project_manager.user
    get :show,:id=>project_manager.projects.first
		assert_select "div.box_about_actor p.project_managers" do
			assert_select "label",:text=>"#{I18n.t('project')} Managers:",:count=>1
			assert_select "a",:count=>1
			assert_select "a[href=?]",person_path(project_manager),:text=>project_manager.name,:count=>1
		end
    end

  test "gatekeepers displayed in show page" do
    gatekeeper = Factory(:gatekeeper)
    login_as gatekeeper.user
    get :show, :id => gatekeeper.projects.first
    assert_select "div.box_about_actor p.gatekeepers" do
      assert_select "label", :text => "Gatekeepers:", :count => 1
      assert_select "a", :count => 1
      assert_select "a[href=?]", person_path(gatekeeper), :text => gatekeeper.name, :count => 1
    end
  end

  test "dont display the roles(except pals) for people who are not the members of this showed project" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)

    asset_manager = Factory(:asset_manager, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    project_manager = Factory(:project_manager, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    gatekeeper = Factory(:gatekeeper, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    pal = Factory(:pal, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

    a_person = Factory(:person)

    assert !a_person.projects.include?(project)

    login_as(a_person.user)
    get :show, :id => project
    assert_select "div.box_about_actor p" do
      assert_select "label", :text => "Asset Managers:", :count => 0
      assert_select "a[href=?]", person_path(asset_manager), :text => asset_manager.name, :count => 0

      assert_select "label", :text => "Project Managers:", :count => 0
      assert_select "a[href=?]", person_path(project_manager), :text => project_manager.name, :count => 0

      assert_select "label", :text => "Gatekeepers:", :count => 0
      assert_select "a[href=?]", person_path(gatekeeper), :text => gatekeeper.name, :count => 0

      assert_select "label", :text => "SysMO-DB PALs:", :count => 1
      assert_select "a[href=?]", person_path(pal), :text => pal.name, :count => 1
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
			assert_select "label",:text=>"SysMO-DB PALs:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No PALs for this #{I18n.t('project')}",:count=>1
		end
  end

  test "no asset managers displayed for project with no asset managers" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    login_as person.user
    get :show,:id=>project
		assert_select "div.box_about_actor p.asset_managers" do
			assert_select "label",:text=>"Asset Managers:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No Asset Managers for this #{I18n.t('project')}",:count=>1
		end
  end

  test "no project managers displayed for project with no project managers" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    login_as person.user
    get :show,:id=>project
		assert_select "div.box_about_actor p.project_managers" do
			assert_select "label",:text=>"#{I18n.t('project')} Managers:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No #{I18n.t('project')} Managers for this #{I18n.t('project')}",:count=>1
		end
	end

  test "no gatekeepers displayed for project with no gatekeepers" do
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    login_as person.user
    get :show,:id=>project
		assert_select "div.box_about_actor p.gatekeepers" do
			assert_select "label",:text=>"Gatekeepers:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No Gatekeepers for this #{I18n.t('project')}",:count=>1
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
		assert_select "ul.sectionIcons" do
			assert_select "span.icon" do
				assert_select "a[href=?]",admin_project_path(project),:text=>/Project administration/,:count=>0
			end
		end
	end

	test "admin has option to administer project" do
    admin = Factory :admin
    assert_equal 1,admin.projects.count
    project = admin.projects.first
    login_as(admin.user)
		get :show,:id=>project
		assert_select "ul.sectionIcons" do
			assert_select "span.icon" do
				assert_select "a[href=?]",admin_project_path(project),:text=>/#{I18n.t('project')} administration/,:count=>1
			end
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

  test 'project manager can administer their projects' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    login_as(project_manager.user)

    get :show, :id => project
    assert_response :success
    assert_select "a", :text => /#{I18n.t('project')} administration/, :count => 1

    get :admin, :id => project
    assert_response :success

    new_institution = Institution.create(:name => 'a test institution')
    put :update, :id => project, :project => {:institution_ids => (project.institutions + [new_institution]).collect(&:id)}
    assert_redirected_to project_path(project)
    project.reload
    assert project.institutions.include?new_institution
  end

  test 'project manager can not administer the projects that they are not in' do
    project_manager = Factory(:project_manager)
    a_project = Factory(:project)
    assert !(project_manager.projects.include?a_project)
    login_as(project_manager.user)

    get :show, :id => a_project
    assert_response :success
    assert_select "a", :text => /Project administration/, :count => 0

    get :admin, :id => a_project
    assert_redirected_to :root
    assert_not_nil flash[:error]

    new_institution = Institution.create(:name => 'a test institution')
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

  test 'project manager can only see all institutions' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    login_as(project_manager.user)
    Factory(:institution)

    get :admin, :id => project
    assert_response :success
    Institution.all.each do |institution|
      assert_select "input[type='checkbox'][value='#{institution.id}']", :count => 1
    end
  end

  test 'project manager can assign all institutions to their project' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    login_as(project_manager.user)
    a_institution = Factory(:institution)

    put :update, :id => project, :project => {:institution_ids => Institution.all.collect(&:id)}
    assert_redirected_to project_path(project)
    project.reload
    assert_equal Institution.count, project.institutions.count
  end

  test 'project manager can not administer sharing policy' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    policy = project.default_policy

		sharing = {}
		sharing[:sharing_scope] = Policy::EVERYONE
    sharing["access_type_#{sharing[:sharing_scope]}"] = Policy::VISIBLE

    assert_not_equal policy.sharing_scope, sharing[:sharing_scope]
    assert_not_equal policy.access_type, sharing["access_type_#{sharing[:sharing_scope]}"]

    login_as(project_manager.user)
		put :update, :id => project.id, :project => valid_project, :sharing => sharing
    project.reload
    assert_redirected_to project
		assert_not_equal project.default_policy.sharing_scope, sharing[:sharing_scope]
    assert_not_equal project.default_policy.access_type, sharing["access_type_#{sharing[:sharing_scope]}"]
  end

  test 'project manager can not administer jerm detail' do
    with_config_value :jerm_enabled,true do
      project_manager = Factory(:project_manager)
      project = project_manager.projects.first
      assert_nil project.site_root_uri
      assert_nil project.site_username
      assert_nil project.site_password

      login_as(project_manager.user)
      put :update, :id => project.id, :project => {:site_root_uri => 'test', :site_username => 'test', :site_password => 'test'}

      project.reload
      assert_redirected_to project
      assert_nil project.site_root_uri
      assert_nil project.site_username
      assert_nil project.site_password
    end
  end

  test "should view_items_in_tab in project page for non-admin" do
    project = Factory(:project)
    df = Factory :data_file,
                 :title=>"a data file",
                 :contributor=>User.current_user,
                 :policy=>Factory(:public_policy),
                 :project_ids => [project.id]

    login_as(Factory(:user))
    get :view_items_in_tab,{:resource_type=>"DataFile",:resource_ids=>[df.id].join(",")}

    assert_response :success
    assert @response.body.include?("a data file")
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

	private

	def valid_project
		return {}
	end
end
