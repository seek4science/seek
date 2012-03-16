require 'test_helper'
require 'libxml'

class ProjectsControllerTest < ActionController::TestCase

	include AuthenticatedTestHelper
	include RestTestCases

	fixtures :all

	def setup
		login_as(:quentin)
		@object=projects(:sysmo_project)
  end

  def test_title
		get :index
		assert_select "title",:text=>/The Sysmo SEEK Projects.*/, :count=>1
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
		assert_difference('Project.count', -1) do
			delete :destroy, :id => projects(:four)
		end

		assert_redirected_to projects_path
	end

	def test_non_admin_should_not_destroy_project
		login_as(:aaron)
		assert_no_difference('Project.count') do
			delete :destroy, :id => projects(:four)
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
		assert_select "a",:text=>/Edit Project/,:count=>1

		get :edit, :id=>projects(:three)
		assert_response :success

		put :update, :id=>projects(:three).id,:project=>{}
		assert_redirected_to project_path(assigns(:project))
	end

	def test_user_project_manager
		login_as(:project_manager)
		get :show, :id=>projects(:three)
		assert_select "a",:text=>/Edit Project/,:count=>1

		get :edit, :id=>projects(:three)
		assert_response :success

		put :update, :id=>projects(:three).id,:project=>{}
		assert_redirected_to project_path(assigns(:project))
	end

	def test_user_cant_edit_project
		login_as(:cant_edit)
		get :show, :id=>projects(:three)
		assert_select "a",:text=>/Edit Project/,:count=>0

		get :edit, :id=>projects(:three)
		assert_response :redirect

		#TODO: Test for update
	end

	def test_admin_can_edit
		get :show, :id=>projects(:one)
		assert_select "a",:text=>/Edit Project/,:count=>1

		get :edit, :id=>projects(:one)
		assert_response :success

		put :update, :id=>projects(:three).id,:project=>{}
		assert_redirected_to project_path(assigns(:project))
	end

	test "links have nofollow in sop tabs" do
		login_as(:owner_of_my_first_sop)
		sop=sops(:my_first_sop)
		sop.description="http://news.bbc.co.uk"
		sop.save!

		get :show,:id=>projects(:sysmo_project)
		assert_select "div.list_item div.list_item_desc" do
			assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
		end
	end

	test "links have nofollow in data_files tabs" do
		login_as(:owner_of_my_first_sop)
		data_file=data_files(:picture)
		data_file.description="http://news.bbc.co.uk"
		data_file.save!

		get :show,:id=>projects(:sysmo_project)
		assert_select "div.list_item div.list_item_desc" do
			assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
		end
	end

	test "links have nofollow in model tabs" do
		login_as(:owner_of_my_first_sop)
		model=models(:teusink)
		model.description="http://news.bbc.co.uk"
		model.save!

		get :show,:id=>projects(:sysmo_project)
		assert_select "div.list_item div.list_item_desc" do
			assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
		end
	end

	test "pals displayed in show page" do
		get :show,:id=>projects(:sysmo_project)
		assert_select "div.box_about_actor p.pals" do
			assert_select "label",:text=>"SysMO-DB PALs:",:count=>1
			assert_select "a",:count=>1
			assert_select "a[href=?]",person_path(people(:pal)),:text=>"A PAL",:count=>1
		end
  end

  	test "asset_managers displayed in show page" do
    asset_manager = Factory(:asset_manager)
    get :show,:id=>asset_manager.projects.first
		assert_select "div.box_about_actor p.asset_managers" do
			assert_select "label",:text=>"SysMO-DB Asset Managers:",:count=>1
			assert_select "a",:count=>1
			assert_select "a[href=?]",person_path(asset_manager),:text=>asset_manager.name,:count=>1
		end
    end

  	test "project_managers displayed in show page" do
		project_manager = Factory(:project_manager)
    get :show,:id=>project_manager.projects.first
		assert_select "div.box_about_actor p.project_managers" do
			assert_select "label",:text=>"SysMO-DB Project Managers:",:count=>1
			assert_select "a",:count=>1
			assert_select "a[href=?]",person_path(project_manager),:text=>project_manager.name,:count=>1
		end
    end

  test "publishers displayed in show page" do
    publisher = Factory(:publisher)
    get :show, :id => publisher.projects.first
    assert_select "div.box_about_actor p.publishers" do
      assert_select "label", :text => "SysMO-DB Publishers:", :count => 1
      assert_select "a", :count => 1
      assert_select "a[href=?]", person_path(publisher), :text => publisher.name, :count => 1
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
			assert_select "span.none_text",:text=>"No PALs for this project",:count=>1
		end
  end

  test "no asset managers displayed for project with no asset managers" do
		project = Factory(:project)
    get :show,:id=>project
		assert_select "div.box_about_actor p.asset_managers" do
			assert_select "label",:text=>"SysMO-DB Asset Managers:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No Asset Managers for this project",:count=>1
		end
  end

  test "no project managers displayed for project with no project managers" do
		project = Factory(:project)
    get :show,:id=>project
		assert_select "div.box_about_actor p.project_managers" do
			assert_select "label",:text=>"SysMO-DB Project Managers:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No Project Managers for this project",:count=>1
		end
	end

  test "no publishers displayed for project with no publishers" do
		project = Factory(:project)
    get :show,:id=>project
		assert_select "div.box_about_actor p.publishers" do
			assert_select "label",:text=>"SysMO-DB Publishers:",:count=>1
			assert_select "a",:count=>0
			assert_select "span.none_text",:text=>"No Publishers for this project",:count=>1
		end
	end

	test "non admin cannot administer project" do
		login_as(:pal_user)
		get :admin,:id=>projects(:sysmo_project)
		assert_response :redirect
		assert_not_nil flash[:error]
	end

	test "admin can administer project" do
		get :admin,:id=>projects(:sysmo_project)
		assert_response :success
		assert_nil flash[:error]
	end

	test "non admin has no option to administer project" do
		login_as(:pal_user)
		get :show,:id=>projects(:sysmo_project)
		assert_select "ul.sectionIcons" do
			assert_select "span.icon" do
				assert_select "a[href=?]",admin_project_path(projects(:sysmo_project)),:text=>/Project administration/,:count=>0
			end
		end
	end

	test "admin has option to administer project" do
		get :show,:id=>projects(:sysmo_project)
		assert_select "ul.sectionIcons" do
			assert_select "span.icon" do
				assert_select "a[href=?]",admin_project_path(projects(:sysmo_project)),:text=>/Project administration/,:count=>1
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
    assert_select "a", :text => /Project administration/, :count => 1

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

  test 'project manager can only see the new institutions (which are not yet in any projects) and the institutions this project' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    login_as(project_manager.user)

    new_institution = Institution.create(:name => 'a test institution')
    a_project = Factory(:project)
    a_project.institutions << Factory(:institution)

    get :admin, :id => project
    assert_response :success
    assert_select "select#project_institution_ids", :count => 1 do
      (project.institutions + [new_institution]).each do |institution|
         assert_select 'option', :text => institution.title, :count => 1
      end
      a_project.institutions.each do |institution|
         assert_select 'option', :text => institution.title, :count => 0
      end
    end
  end

  test 'project manager can assign only the new institutions (which are not yet in any projects) to their project' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    login_as(project_manager.user)

    new_institution = Institution.create(:name => 'a test institution')

    put :update, :id => project, :project => {:institution_ids => (project.institutions + [new_institution]).collect(&:id)}
    assert_redirected_to project_path(project)
    project.reload
    assert project.institutions.include?new_institution
  end

  test 'project manager can not assign the institutions (which are already in the other projects) to their project' do
    project_manager = Factory(:project_manager)
    project = project_manager.projects.first
    a_project = Factory(:project)
    a_project.institutions << Factory(:institution)

    login_as(project_manager.user)

    put :update, :id => project, :project => {:institution_ids => (project.institutions + a_project.institutions).collect(&:id)}
    assert_redirected_to :root
    assert_not_nil flash[:error]
    project.reload
    a_project.institutions.each do |i|
       assert !(project.institutions.include?i)
    end
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

	private

	def valid_project
		return {}
	end
end
