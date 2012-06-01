require 'test_helper'

class PoliciesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test 'should show the preview permission when choosing public scope' do
    post :preview_permissions, :sharing_scope => 4, :access_type => 2, :resource_name => 'data_file'

    assert_response :success
    assert_select "p",:text=>"All visitors (including anonymous visitors with no login) can view summary and get contents",:count=>1
  end

  test 'should show the preview permission when choosing private scope' do
    post :preview_permissions, :sharing_scope => 0

    assert_response :success
    assert_select "p",:text=>"You keep this item private (only visible to you)", :count=>1
  end

  test 'should show the preview permission when choosing network scope' do
    #create your project and member
    your_project = Factory(:project)
    your_work_group = Factory(:work_group, :project => your_project)
    your_project_member = Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => your_work_group)])

    #create some projects and members
    i=0
    network_members = []
    while i<5
      network_members.push Factory(:person_in_project)
      i +=1
    end

    #set access_type for your project = Policy::ACCESSIBLE, network = Policy::VISIBLE
    post :preview_permissions, :sharing_scope => 2, :access_type => Policy::VISIBLE, :project_ids => your_project.id.to_s, :project_access_type => Policy::ACCESSIBLE

    assert_response :success
    assert_select "h2",:text=>"People who can view the summary:", :count=>1
    network_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People who can view the summary and get contents:", :count=>1
    assert_select 'a', :text=>"#{your_project_member.first_name} #{your_project_member.last_name}", :count => 1
  end

  test 'should show the preview permission when custom the permissions for Person, Project and FavouriteGroup' do
    contributor_types = ['Person', 'FavouriteGroup', 'Project']
    contributor_values = {}

    user = Factory(:user)
    login_as(user)

    #create a person and set access_type to Policy::MANAGING
    person =  Factory(:person_in_project)
    contributor_values['Person']= {person.id => {"access_type" => Policy::MANAGING}}

    #create a favourite group and members, set access_type to Policy::EDITING
    favorite_group = Factory(:favourite_group, :user => user)
    fg_members = []
    i=0
    while i<5
      person_in_fg = Factory(:person)
      Factory(:favourite_group_membership, :favourite_group => favorite_group, :person => person_in_fg, :access_type => Policy::EDITING )
      fg_members.push person_in_fg
      i +=1
    end
    contributor_values['FavouriteGroup']= {favorite_group.id => {"access_type" => -1}}

    #create a project and members and set access_type to Policy::ACCESSIBLE
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    project_members = []
    i=0
    while i<5
      project_members.push Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
      i +=1
    end
    contributor_values['Project']= {project.id => {"access_type" => Policy::ACCESSIBLE}}

    post :preview_permissions, :sharing_scope => 0, :contributor_types => ActiveSupport::JSON.encode(contributor_types), :contributor_values => ActiveSupport::JSON.encode(contributor_values)

    assert_response :success
    assert_select "h2",:text=>"People who can view the summary and get contents:", :count=>1
    project_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People who can view and edit the summary and contents:", :count=>1
    fg_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People who can manage:", :count=>1
    assert_select 'a', :text=>"#{person.first_name} #{person.last_name}", :count => 1
  end

  test 'should show the preview permission when choosing blacklist and whitelist' do
    user = Factory(:user)
    login_as(user)

    #create a blacklist and members
    black_list = Factory(:favourite_group, :user => user, :name => '__blacklist__')
    black_list_members = []
    i=0
    while i<5
      person_in_bl = Factory(:person)
      Factory(:favourite_group_membership, :favourite_group => black_list, :person => person_in_bl, :access_type => Policy::NO_ACCESS )
      black_list_members.push person_in_bl
      i +=1
    end

    #create a whitelist and members
    white_list = Factory(:favourite_group, :user => user, :name => '__whitelist__')
    white_list_members = []
    i=0
    while i<5
      person_in_wl = Factory(:person)
      Factory(:favourite_group_membership, :favourite_group => white_list, :person => person_in_wl, :access_type => Policy::ACCESSIBLE )
      white_list_members.push person_in_wl
      i +=1
    end

    post :preview_permissions, :sharing_scope => 0, :use_blacklist => 'true', :use_whitelist => 'true'

    assert_select "h2",:text=>"People who have no access:", :count=>1
    black_list_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People who can view the summary and get contents:", :count=>1
    white_list_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end
  end

  test 'should show the correct manager(contributor) when updating a study' do
    study = Factory(:study)
    contributor = study.contributor
    post :preview_permissions, :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE, :is_new_file => "false", :contributor_id => contributor.user.id

    assert_select "h2",:text=>"People who can manage:", :count=>1
    assert_select 'a', :count => 1
    assert_select 'a', :text=>"#{contributor.name}", :count => 1
  end

  test 'when creating an item, can not publish the item if associate to it the project which has gatekeeper' do
      gatekeeper = Factory(:gatekeeper)
      a_person = Factory(:person)
      sample = Sample.new

      login_as(a_person.user)
      assert sample.can_manage?
      assert sample.can_publish?

      put :updated_can_publish, :project_ids => gatekeeper.projects.first.id, :resource_name => 'sample', :resource_id => sample.id
      assert_response :success

      json_response = ActiveSupport::JSON.decode(@response.body)
      assert !json_response["updated_can_publish"]
  end

  test 'when creating an item, can publish the item if associate to it the project which has no gatekeeper' do
        a_person = Factory(:person)
        sample = Sample.new

        login_as(a_person.user)
        assert sample.can_manage?
        assert sample.can_publish?

        put :updated_can_publish, :project_ids => Factory(:project).id, :resource_name => 'sample', :resource_id => sample.id
        assert_response :success

        json_response = ActiveSupport::JSON.decode(@response.body)
        assert json_response["updated_can_publish"]
    end

  test 'when updating an item, can not publish the item if associate to it the project which has gatekeeper' do
    gatekeeper = Factory(:gatekeeper)
    a_person = Factory(:person)
    sample = Factory(:sample, :policy => Factory(:policy))
    Factory(:permission, :contributor => a_person, :access_type => Policy::MANAGING, :policy => sample.policy)
    sample.reload

    login_as(a_person.user)
    assert sample.can_manage?
    assert sample.can_publish?

    put :updated_can_publish, :project_ids => gatekeeper.projects.first.id, :resource_name => 'sample', :resource_id => sample.id
    assert_response :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert !json_response["updated_can_publish"]
  end

  test 'when updating an item, can publish the item if dissociate to it the project which has gatekeeper' do
        gatekeeper = Factory(:gatekeeper)
        a_person = Factory(:person)
        sample = Factory(:sample, :policy => Factory(:policy), :projects => gatekeeper.projects)
        Factory(:permission, :contributor => a_person, :access_type => Policy::MANAGING, :policy => sample.policy)
        sample.reload

        login_as(a_person.user)
        assert sample.can_manage?
        assert !sample.can_publish?

        put :updated_can_publish, :project_ids => Factory(:project).id, :resource_name => 'sample', :resource_id => sample.id
        assert_response :success

        json_response = ActiveSupport::JSON.decode(@response.body)
        assert json_response["updated_can_publish"]
  end

  test 'can publish assay without study' do
    a_person = Factory(:person)
    assay = Assay.new

    login_as(a_person.user)
    assert assay.can_manage?
    assert assay.can_publish?

    put :updated_can_publish, :project_ids => '', :resource_name => 'assay', :resource_id => assay.id
    assert_response :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["updated_can_publish"]
  end

  test 'can not publish assay having project with gatekeeper' do
    gatekeeper = Factory(:gatekeeper)
    a_person = Factory(:person)
    assay = Assay.new
    assay.study = Factory(:study, :investigation => Factory(:investigation, :projects => gatekeeper.projects))

    login_as(a_person.user)
    assert assay.can_manage?
    assert !assay.can_publish?

    put :updated_can_publish, :project_ids => assay.study.id, :resource_name => 'assay', :resource_id => assay.id
    assert_response :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert !json_response["updated_can_publish"]
  end
end