require 'test_helper'

class PoliciesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  #Tests for preview permission
  #In a group, when a person can perform an item with different access_type, choose the highest access_type
  test "remove duplication by choosing the highest access_type" do
    #create a bundle of people array
    people_with_access_type = []
    i = 0
    access_type = 1
    while i<10
      people_with_access_type.push [i, 'name' + i.to_s, access_type ]
      i +=1
    end
    #create duplication
    i = 0
    access_type = 1
    while i<10
      people_with_access_type.push [i, 'name' + i.to_s, access_type ]
      i +=1
    end
    #create duplication but with different access_type
    i = 0
    max_access_type = 2
    while i<10
      people_with_access_type.push [i, 'name' + i.to_s, max_access_type ]
      i +=1
    end
    #remove duplication by choosing the highest access_type
    people_with_highest_access_type = PoliciesController.new().remove_duplicate(people_with_access_type)

    assert_equal 10, people_with_highest_access_type.count
    people_with_highest_access_type.each do |person|
      assert_equal max_access_type, person[2]
    end
    #the array is unique
    assert_equal people_with_highest_access_type.uniq, people_with_highest_access_type
  end

  #if a person in 2 groups perform different access_type on an item, select the access_type of a group which has higher precedence
  test "should get access_type from the precedence group" do
    #create 2 groups with bundle of people, people from group 1 have random access_type, people from group 2 have fix access_type
    people_in_group1 = []
    people_in_group2 = []
    i = 0
    access_type = 2
    while i<10
      people_in_group1.push [i, 'name' + i.to_s, rand(4) ]
      people_in_group2.push [i, 'name' + i.to_s, access_type ]
      i +=1
    end
    #group 2 has higher precedence than group 1
    filtered_people = PoliciesController.new().precedence(people_in_group1, people_in_group2)
    filtered_people.each do |person|
      assert_equal access_type, person[2]
    end
  end

  test'should remove people who are in the blacklist' do
    #create bundle of people
    people_with_access_type = []
    i = 0
    while i<10
      people_with_access_type.push [i, 'name' + i.to_s, rand(5) ]
      i +=1
    end
    #create a blacklist
    black_list = []
    i = 0
    while i<5
      random_id = rand(10)
      black_list.push [random_id, 'name' + random_id.to_s, 0 ]
      i +=1
    end
    black_list.uniq!
    black_list_ids = black_list.collect{|person| person[0]}
    filtered_people = PoliciesController.new().remove_people_in_blacklist(people_with_access_type, black_list)

    assert_equal (people_with_access_type.count - black_list.count), filtered_people.count

    filtered_people.each do |person|
      assert !black_list_ids.include?(person[1])
    end
  end

  test'should add people who are in the whitelist' do
    #create bundle of people
    people_with_access_type = []
    i = 0
    while i<10
      people_with_access_type.push [i, 'name' + i.to_s, 1]
      i +=1
    end
    #create a whitelist
    whitelist = []
    i = 0
    while i<5
      random_id = rand(15)
      whitelist.push [random_id, 'name' + random_id.to_s, rand(5)]
      i +=1
    end
    whitelist.uniq!
    pc =  PoliciesController.new()
    whitelist =  pc.remove_duplicate(whitelist)
    whitelist_added= whitelist.select{|person| person[0]>9}
    filtered_people = pc.add_people_in_whitelist(people_with_access_type, whitelist)

    assert_equal (people_with_access_type.count + whitelist_added.count), filtered_people.count

    filtered_people.each do |person|
      assert person[2] >= 1
    end
  end

  test 'should show the preview permission when choosing public scope' do
    post :preview_permissions, :sharing_scope => 4, :access_type => 1

    assert_response :success
    assert_select "p",:text=>"All visitors (including anonymous visitors with no login) can #{Policy.get_access_type_wording(1, nil).downcase}",:count=>1
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
    assert_select "h2",:text=>"People can view summary:", :count=>1
    network_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People can view summary and get contents:", :count=>1
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
    assert_select "h2",:text=>"People can view summary and get contents:", :count=>1
    project_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People can view and edit summary and contents:", :count=>1
    fg_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People can manage:", :count=>1
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

    assert_select "h2",:text=>"People have no access:", :count=>1
    black_list_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end

    assert_select "h2",:text=>"People can view summary and get contents:", :count=>1
    white_list_members.each do |member|
      assert_select 'a', :text=>"#{member.first_name} #{member.last_name}", :count => 1
    end
  end

end