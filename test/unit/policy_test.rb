require 'test_helper'

class PolicyTest < ActiveSupport::TestCase

  fixtures :all

  test "deep clone" do
    policy = policies(:download_for_all_sysmo_users_policy)

    copy = policy.deep_copy    
    assert_equal policy.sharing_scope,copy.sharing_scope
    assert_equal policy.access_type,copy.access_type
    assert_equal policy.name,copy.name
    assert_not_equal policy.id,copy.id

    assert policy.permissions.size>0,"needs to have custom permissions to make this test meaningful"
    assert copy.permissions.size>0,"needs to have custom permissions to make this test meaningful"

    assert_equal policy.permissions.size,copy.permissions.size

    policy.permissions.each_with_index do |perm,i|
      copy_perm = copy.permissions[i]
      assert_equal perm.contributor,copy_perm.contributor      
      assert_equal perm.access_type,copy_perm.access_type
      assert_not_equal perm.id,copy_perm.id      
    end
  end
  
  test "private policy" do
    pol=Policy.private_policy
    assert_equal Policy::PRIVATE, pol.sharing_scope
    assert_equal Policy::NO_ACCESS, pol.access_type
    assert_equal false,pol.use_whitelist
    assert_equal false,pol.use_blacklist
    assert pol.permissions.empty?
  end

  test "default policy" do
    pol=Policy.default
    assert_equal Policy::PRIVATE, pol.sharing_scope
    assert_equal Policy::NO_ACCESS, pol.access_type
    assert_equal false,pol.use_whitelist
    assert_equal false,pol.use_blacklist
    assert pol.permissions.empty?
  end

  test "policy access type presedence" do
    assert Policy::NO_ACCESS < Policy::VISIBLE
    assert Policy::VISIBLE < Policy::ACCESSIBLE
    assert Policy::ACCESSIBLE < Policy::EDITING
    assert Policy::EDITING < Policy::MANAGING
  end

  test "policy sharing scope presedence" do
    assert Policy::PRIVATE < Policy::ALL_SYSMO_USERS
    assert Policy::ALL_SYSMO_USERS < Policy::EVERYONE
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
    people_with_highest_access_type = Policy.new().remove_duplicate(people_with_access_type)

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
    filtered_people = Policy.new().precedence(people_in_group1, people_in_group2)
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
    filtered_people = Policy.new().remove_people_in_blacklist(people_with_access_type, black_list)

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
      people_with_access_type.push [i, 'name' + i.to_s, rand(4) + 1]
      i +=1
    end
    #create a whitelist
    whitelist = []
    i = 0
    while i<5
      random_id = rand(15)
      whitelist.push [random_id, 'name' + random_id.to_s, 2]
      i +=1
    end
    whitelist =  Policy.new().remove_duplicate(whitelist)
    whitelist_added= whitelist.select{|person| person[0]>9}
    filtered_people = Policy.new().add_people_in_whitelist(people_with_access_type, whitelist)
    assert_equal (people_with_access_type.count + whitelist_added.count), filtered_people.count
  end
end
