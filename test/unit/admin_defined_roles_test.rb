require 'test_helper'

class AdminDefinedRolesTest < ActiveSupport::TestCase

  def setup
    User.current_user = Factory(:admin).user
  end

  test "cannot add a role with a project the person is not a member of" do
    person = Factory(:person)
    project1 = person.projects.first
    project2 = Factory(:project)

    assert !person.is_gatekeeper?(project1)
    assert !person.is_gatekeeper?(project2)

    person.roles = [["gatekeeper",[project1,project2]]]

    assert person.is_gatekeeper?(project1)
    assert !person.is_gatekeeper?(project2)

    assert !person.is_asset_manager?(project2)
    person.is_asset_manager=true,project2
    assert !person.is_asset_manager?(project2)

  end

  test "removing a person from a project removes that role" do
    Factory(:admin) #prevents this following person also becoming an admin due to being first
    person = Factory(:project_manager)
    project = person.projects.first

    assert person.is_project_manager?(project)
    assert person.is_project_manager_of_any_project?

    assert_difference("AdminDefinedRoleProject.count",-1) do
      person.work_groups=[]
      person.save!
    end

    person.reload

    refute_includes person.projects,project, "should no longer be a member of that project"

    assert !person.is_project_manager?(project), "should no longer be project manager for that project"
    assert !person.is_project_manager_of_any_project?, "should no longer be a project manager at all"
    assert_equal 0,person.roles_mask
  end

  test "destroying a person destroys the project role details" do
    person = Factory(:asset_manager)
    User.with_current_user(Factory(:admin).user) do
      person.is_pal=true,person.projects.first
      person.save!
    end

    assert_difference("AdminDefinedRoleProject.count",-2) do
      person.destroy
    end
  end

  test "raises exception for unrecognised role" do
    person = Factory(:person)
    project = person.projects.first
    assert_raises Seek::AdminDefinedRoles::UnknownRoleException do
      person.roles=[["fish",project]]
    end
  end

  test "role_names" do
    person = Factory(:admin)
    assert_equal ["admin"],person.role_names

    person = Factory(:gatekeeper)
    assert_equal ["gatekeeper"],person.role_names
    person = Factory(:asset_manager)
    assert_equal ["asset_manager"],person.role_names
    person = Factory(:project_manager)
    assert_equal ["project_manager"],person.role_names
    person = Factory(:pal)
    assert_equal ["pal"],person.role_names

    project = person.projects.first
    person.is_gatekeeper=true,project
    assert_equal ["gatekeeper","pal"],person.role_names.sort

    person.is_admin=true
    assert_equal ["admin","gatekeeper","pal"],person.role_names.sort

    person.is_asset_manager=true,project
    assert_equal ["admin","asset_manager","gatekeeper","pal"],person.role_names.sort

    person.is_project_manager=true,project
    assert_equal ["admin","asset_manager","gatekeeper","pal","project_manager"],person.role_names.sort

  end

  test "project dependent roles" do
    assert_equal ['pal', 'project_manager', 'asset_manager', 'gatekeeper'],Person::PROJECT_DEPENDENT_ROLES
    assert Person.is_project_dependent_role?('pal')
    assert Person.is_project_dependent_role?('project_manager')
    assert Person.is_project_dependent_role?('asset_manager')
    assert Person.is_project_dependent_role?('gatekeeper')
    assert !Person.is_project_dependent_role?('admin')
  end

  test "changing the project on a role" do
    User.with_current_user Factory(:admin).user do
      person = Factory :person_in_multiple_projects
      project1=person.projects.first
      project2=person.projects.last
      assert_not_equal project1,project2
      person.roles=[['pal',project1]]
      assert person.is_pal?(project1)
      assert !person.is_pal?(project2)

      person.roles=[['pal',project2]]
      assert person.is_pal?(project2)
      assert !person.is_pal?(project1)
    end
  end

  test "setting and retrieving roles using a string or int project id" do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person_in_multiple_projects)
      project_ids=person.projects.collect{|p| p.id}
      person.roles=[['gatekeeper',project_ids],['pal',project_ids.first.to_s]]
      assert_equal ['gatekeeper','pal'],person.roles(project_ids.first).sort
      assert_equal ['gatekeeper'],person.roles(project_ids[1])
      assert_equal ['gatekeeper'],person.roles(project_ids[2].to_s)
    end
  end

  test "mixing admin with project dependent roles" do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      person.roles = [['admin'],['gatekeeper',project]]
      person.save!
      person.reload
      assert person.is_admin?
      assert person.is_gatekeeper?(project)
      assert_equal ['admin','gatekeeper'],person.roles(project)
    end
  end

  test 'assign asset_manager role for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person_in_multiple_projects)
      person2 = Factory(:person_in_multiple_projects)
      assert person.projects.count>1
      assert person2.projects.count>1

      project = person.projects.first
      projects = person2.projects[1..3]
      other_project=person2.projects.first

      assert_equal [], person.roles
      assert person.can_manage?
      person.roles=[['asset_manager',project]]
      person.save!
      person.reload
      assert_equal ['asset_manager'], person.roles(project)
      assert_equal [],person.roles(other_project)

      person2.roles=[['asset_manager',projects]]
      person2.save!
      person2.reload
      assert_equal ['asset_manager'], person2.roles(projects[0])
      assert_equal ['asset_manager'], person2.roles(projects[1])
      assert_equal [],person2.roles(other_project)

      person2.is_asset_manager=false,projects[0]
      person2.save!
      person2.reload
      assert_equal [], person2.roles(projects[0])
      assert_equal ['asset_manager'], person2.roles(projects[1])

      person2.is_asset_manager=true,projects[0]
      person2.save!
      person2.reload
      assert_equal ['asset_manager'], person2.roles(projects[0])
      assert_equal ['asset_manager'], person2.roles(projects[1])
    end
  end

  test 'add roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      assert_equal 1,person.projects.count
      project = person.projects.first
      assert person.roles.empty?
      assert person.can_manage?
      person.add_roles [['pal',project]]
      person.save!
      person.reload
      assert_equal ['pal'], person.roles(project)
      assert person.is_pal?(project)
      assert !person.is_pal?
    end
  end

  test 'add roles for admin' do
     User.with_current_user Factory(:admin).user do
       person = Factory(:admin)
       project = person.projects.first
       assert_equal ['admin'], person.roles

       #pass admin role
       person.roles = [['admin'],['pal',project]]
       person.save!
       person.reload
       assert_equal ['admin', 'pal'].sort, person.roles(project).sort
       assert person.is_admin?
       assert person.is_pal?(project)
       assert !person.is_pal?

      #pass not admin role
       person.roles =[['pal',project]]
       person.save!
       person.reload
       assert_equal ['admin', 'pal'].sort, person.roles(project).sort
       assert person.is_admin?
       assert person.is_pal?(project)
       assert !person.is_pal?
     end
  end
  test 'update roles directly' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      person.roles = [['asset_manager',project], ['pal',project]]
      person.save!
      person.reload
      assert_equal ['asset_manager','pal'], person.roles(project).sort

      person.roles = [['pal',project]]
      person.save!
      person.reload
      assert_equal ['pal'], person.roles(project)

      person2 = Factory(:person_in_multiple_projects)
      project = person2.projects.first
      project2 = person2.projects[1]
      project3 = person2.projects[2]
      person2.roles = [['asset_manager',project], ['pal',project]]
      assert_equal ['asset_manager','pal'],person2.roles(project).sort
      person2.roles = [['asset_manager',project], ['pal',project2]]
      assert_equal ['asset_manager'],person2.roles(project)
      assert_equal ['pal'],person2.roles(project2)
      assert_equal [],person2.roles(project3)
    end
  end

  test "updating roles with assignment" do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person_in_multiple_projects)
      project = person.projects.first

      person.is_admin=true
      person.save!
      person.reload
      assert_equal ['admin'],person.roles(project)
      assert person.is_admin?
      assert !person.is_gatekeeper?(project)

      person.is_asset_manager=true,project
      person.save!
      person.reload
      assert_equal ['admin','asset_manager'],person.roles(project).sort
      assert person.is_admin?
      assert person.is_asset_manager?(project)
      assert !person.is_gatekeeper?(project)

      person.is_asset_manager=false,project
      person.is_pal=true,project

      person.save!
      person.reload
      assert_equal ['admin','pal'],person.roles(project).sort
      assert person.is_admin?
      assert person.is_pal?(project)
      assert !person.is_asset_manager?(project)
      assert !person.is_gatekeeper?(project)

      project2=person.projects.last
      person.is_pal=true,project2
      assert person.is_pal?(project)
      assert !person.is_asset_manager?(project)
      assert !person.is_gatekeeper?(project)
      assert person.is_pal?(project2)
      assert !person.is_asset_manager?(project2)
      assert !person.is_gatekeeper?(project2)

    end
  end

  test 'non-admin can not change the roles of a person' do
    Factory(:admin)#needed to avoid the next person becoming an admin due to being the first person
    person = Factory(:person)
    User.with_current_user person.user do
      project = person.projects.first
      person.roles = [['asset_manager',project], ['pal',project]]
      assert person.can_edit?
      assert !person.save
      assert !person.errors.empty?
      person.reload
      assert_equal [], person.roles(project)
    end
  end

  test "projects for role" do
    person = Factory :person_in_multiple_projects
    p1 = person.projects[0]
    p2 = person.projects[1]

    User.with_current_user(Factory(:admin).user) do
      person.is_gatekeeper=true,[p1,p2]
      person.is_pal=true,p1
      person.is_admin=true
    end

    assert_equal [p1],person.projects_for_role("pal")
    assert_equal [p1,p2].sort,person.projects_for_role("gatekeeper").sort
    assert_equal [],person.projects_for_role("asset_manager")


  end

  test 'is_admin?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)

      person.is_admin = true
      person.save!
      person.reload

      assert person.is_admin?

      person.is_admin = false
      person.save!

      assert !person.is_admin?
    end
  end

  test 'is_pal?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_pal = true,project
      person.save!

      assert person.is_pal?(project)
      assert !person.is_pal?(other_project)

      person.is_pal = false,project
      person.save!

      assert !person.is_pal?(project)
    end
  end

  test 'is_project_manager?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_project_manager= true,project
      person.save!

      assert person.is_project_manager?(project)
      assert !person.is_project_manager?(other_project)

      person.is_project_manager=false,project
      person.save!

      assert !person.is_project_manager?(project)
    end
  end

  test 'is_gatekeeper?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_gatekeeper= true,project
      person.save!

      assert person.is_gatekeeper?(project)
      assert !person.is_gatekeeper?(other_project)

      person.is_gatekeeper=false,project
      person.save!

      assert !person.is_gatekeeper?(project)
    end
  end

  test 'is_asset_manager?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_asset_manager = true,project
      person.save!

      assert person.is_asset_manager?(project)
      assert !person.is_asset_manager?(other_project)

      person.is_asset_manager=false,project
      person.save!

      assert !person.is_asset_manager?(project)
    end
  end

  test 'is_asset_manager_of?' do
    asset_manager = Factory(:asset_manager)
    sop = Factory(:sop)
    assert !asset_manager.is_asset_manager_of?(sop)

    disable_authorization_checks{sop.projects = asset_manager.projects}

    assert asset_manager.is_asset_manager_of?(sop)
  end

  test 'is_gatekeeper_of?' do
    gatekeeper = Factory(:gatekeeper)
    sop = Factory(:sop)
    assert !gatekeeper.is_gatekeeper_of?(sop)

    disable_authorization_checks{sop.projects = gatekeeper.projects}
    assert gatekeeper.is_gatekeeper_of?(sop)
  end

  test "order of ROLES" do
    assert_equal %w[admin pal project_manager asset_manager gatekeeper],Person::ROLES,"The order of the ROLES is critical as it determines the mask that is used."
  end

  test "factories for roles" do
    User.with_current_user Factory(:admin).user do
      admin = Factory(:admin)
      assert admin.is_admin?
      assert admin.save

      pal = Factory(:pal)
      pal.reload
      assert_equal 2,pal.roles_mask,"mask should be 2"
      assert !pal.projects.empty?
      assert pal.is_pal?(pal.projects.first)
      assert pal.save

      gatekeeper = Factory(:gatekeeper)
      assert !gatekeeper.projects.empty?
      assert gatekeeper.is_gatekeeper?(gatekeeper.projects.first)
      assert gatekeeper.save

      asset_manager = Factory(:asset_manager)
      assert !asset_manager.projects.empty?
      assert asset_manager.is_asset_manager?(asset_manager.projects.first)
      assert asset_manager.save

      project_manager = Factory(:project_manager)
      assert !project_manager.projects.empty?
      assert project_manager.is_project_manager?(project_manager.projects.first)
      assert project_manager.save
    end

  end

  test "is project manager regardless of project" do
    admin = Factory(:admin)
    pm = Factory(:project_manager)
    normal = Factory(:person)
    assert !admin.is_project_manager?(nil,true)
    assert !normal.is_project_manager?(nil,true)
    assert pm.is_project_manager?(nil,true)

    assert !admin.is_project_manager_of_any_project?
    assert !normal.is_project_manager_of_any_project?
    assert pm.is_project_manager_of_any_project?

  end

  test 'Person.pals' do
      admin = Factory(:admin)
      normal = Factory(:person)
      pal = Factory(:pal)
      pal2 = Factory(:project_manager)
      pal2.is_pal=true,pal2.projects.first
      pal2.save!

      pals = Person.pals

      assert pals.include?(pal)
      assert pals.include?(pal2)
      assert !pals.include?(normal)
  end

  test 'Person.admins' do
    admin = Factory(:admin)
    admin2 = Factory(:project_manager)
    admin2.is_admin=true
    admin2.save!
    normal = Factory(:person)

    admins = Person.admins
    assert admins.include?(admin)
    assert admins.include?(admin2)
    assert !admins.include?(normal)
  end

  test "Person.gatekeepers" do
    normal = Factory(:person)
    gatekeeper = Factory(:gatekeeper)
    gatekeeper2 = Factory(:project_manager)
    gatekeeper2.is_gatekeeper=true,gatekeeper2.projects.first
    gatekeeper2.save!

    gatekeepers = Person.gatekeepers
    assert gatekeepers.include?(gatekeeper)
    assert gatekeepers.include?(gatekeeper2)
    assert !gatekeepers.include?(normal)
  end

  test "Person.asset_managers" do
    normal = Factory(:person)
    asset_manager = Factory(:asset_manager)
    asset_manager2 = Factory(:project_manager)
    asset_manager2.is_asset_manager=true,asset_manager2.projects.first
    asset_manager2.save!

    asset_managers = Person.asset_managers
    assert asset_managers.include?(asset_manager)
    assert !asset_managers.include?(normal)
  end

  test "Person.project_managers" do
    normal = Factory(:person)
    project_manager = Factory(:project_manager)
    project_manager2 = Factory(:gatekeeper)
    project_manager2.is_project_manager=true,project_manager2.projects.first
    project_manager2.save!

    project_managers = Person.project_managers
    assert project_managers.include?(project_manager)
    assert project_managers.include?(project_manager2)
    assert !project_managers.include?(normal)
  end

  test "is_in_any_gatekept_projects?" do
    normal = Factory(:person)
    gatekeeper = Factory(:gatekeeper)
    assert !normal.is_in_any_gatekept_projects?

    another_normal = Factory :person,
                             :group_memberships=>[Factory(:group_membership,
                                                          :work_group=>gatekeeper.group_memberships.first.work_group)]
    assert another_normal.is_in_any_gatekept_projects?
  end
end