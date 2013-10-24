require 'test_helper'

class AdminDefinedRolesTest < ActiveSupport::TestCase

  test "cannot add a role with a project the person is not a member of" do
    fail "not yet implemented"
  end

  test "removing a person from a project removes that role" do
    fail "not yet implemented"
  end

  test "raises exception for unrecognised role" do
    fail "not yet implemented"
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

  test "setting and retrieving roles using a project id" do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person_in_multiple_projects)
      project_ids=person.projects.collect{|p| p.id}
      person.roles=[['gatekeeper',project_ids],['pal',project_ids.first]]
      assert_equal ['gatekeeper','pal'],person.roles(project_ids.first).sort
      assert_equal ['gatekeeper'],person.roles(project_ids[1])
      assert_equal ['gatekeeper'],person.roles(project_ids[2])
    end
  end

  test "mixing admin with project dependent roles" do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      person.roles = [['admin'],['gatekeeper',project]]
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
      assert_equal ['asset_manager'], person.roles(projects[0])
      assert_equal ['asset_manager'], person.roles(projects[1])
      assert_equal [],person.roles(other_project)

      person2.is_admin=false,projects[0]
      assert_equal [], person.roles(projects[0])
      assert_equal ['asset_manager'], person.roles(projects[1])

      person2.is_admin=true,projects[0]
      assert_equal ['asset_manager'], person.roles(projects[0])
      assert_equal ['asset_manager'], person.roles(projects[1])
    end
  end

  test 'add roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:admin)
      assert_equal 1,person.projects.count
      project = person.projects.first
      assert_equal ['admin'], person.roles(project)
      assert person.can_manage?
      person.add_roles [['admin',project],['pal',project]]
      person.save!
      person.reload
      assert_equal ['admin', 'pal'].sort, person.roles(project).sort
    end
  end

  test 'update roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      person.roles = [['asset_manager',project], ['pal',project]]
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

  test 'non-admin can not change the roles of a person' do
    admin = Factory(:admin)#needed to avoid the next person becoming an admin due to being the first person
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

  test 'is_admin?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_admin = true
      person.save!

      assert person.is_admin?
      assert !person.is_admin?

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
      assert !person.is_project_manager(other_project)

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
      assert !person.is_gatekeeper(other_project)

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

  test 'replace admins, pals named_scope by a static function' do
    Person.destroy_all
    admin = Factory(:admin)
    normal = Factory(:person)
    pal = Factory(:pal)

    admins = Person.admins

    assert admins.include?(admin)
    assert !admins.include?(normal)
    assert !admins.include?(pal)

    pals = Person.pals

    assert pals.include?(pal)
    assert !pals.include?(admin)
    assert !pals.include?(normal)
  end
end