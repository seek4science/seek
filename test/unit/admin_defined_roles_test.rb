require 'test_helper'

class AdminDefinedRolesTest < ActiveSupport::TestCase
  def setup
    User.current_user = Factory(:admin).user
  end

  test 'cannot add a role with a project the person is not a member of' do
    person = Factory(:person)
    project1 = person.projects.first
    project2 = Factory(:project)

    refute person.is_asset_gatekeeper?(project1)
    refute person.is_asset_gatekeeper?(project2)

    person.is_asset_gatekeeper = true, [project1, project2]

    assert person.is_asset_gatekeeper?(project1)
    refute person.is_asset_gatekeeper?(project2)

    refute person.is_asset_housekeeper?(project2)
    person.is_asset_housekeeper = true, project2
    refute person.is_asset_housekeeper?(project2)
  end

  test 'removing a person from a project removes that role' do
    Factory(:admin) # prevents this following person also becoming an admin due to being first
    person = Factory(:project_administrator)
    project = person.projects.first

    assert person.is_project_administrator?(project)
    assert person.is_project_administrator_of_any_project?

    assert_difference('AdminDefinedRoleProject.count', -1) do
      person.work_groups = []
      person.save!
    end

    person.reload

    refute_includes person.projects, project, 'should no longer be a member of that project'

    refute person.is_project_administrator?(project), 'should no longer be project administrator for that project'
    refute person.is_project_administrator_of_any_project?, 'should no longer be a project administrator at all'
    assert_equal 0, person.roles_mask
  end

  test 'remove_roles' do
    person = Factory(:programme_administrator)
    project = person.projects.first
    person.is_asset_gatekeeper = true, project
    person.is_project_administrator = true, project
    person.is_asset_gatekeeper = true, project
    person.is_pal = true, project
    person.is_admin = true
    person.save!

    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_project_administrator?(project)
    assert person.is_asset_gatekeeper?(project)
    assert person.is_pal?(project)
    assert person.is_admin?

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: 'project_administrator', items: [project])])

    assert person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    assert person.is_asset_gatekeeper?(project)
    assert person.is_pal?(project)
    assert person.is_admin?

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: 'asset_gatekeeper', items: [project])])

    assert person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    assert person.is_pal?(project)
    assert person.is_admin?

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: 'pal', items: [project])])

    assert person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_pal?(project)
    assert person.is_admin?

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: 'programme_administrator', items: person.programmes)])

    refute person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_pal?(project)
    assert person.is_admin?

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: 'admin')])

    refute person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_pal?(project)
    refute person.is_admin?

    # roles mask isn;t affected if roving a role somebody doesn't belong to
    person = Factory(:programme_administrator)
    project = person.projects.first
    person.is_pal = true, project
    person.save!
    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_pal?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_admin?
    assert_equal 34, person.roles_mask

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: Seek::Roles::ASSET_GATEKEEPER, items: [])])

    assert_equal 34, person.roles_mask
    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_pal?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_admin?

    person.remove_roles([Seek::Roles::RoleInfo.new(role_name: 'admin', items: [])])

    assert_equal 34, person.roles_mask
    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_pal?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_admin?
  end

  test 'destroying a person destroys the project role details' do
    person = Factory(:asset_housekeeper)
    User.with_current_user(Factory(:admin).user) do
      person.is_pal = true, person.projects.first
      person.save!
    end

    assert_difference('AdminDefinedRoleProject.count', -2) do
      person.destroy
    end
  end

  test 'roles' do
    person = Factory(:admin)
    assert_equal ['admin'], person.roles

    person = Factory(:asset_gatekeeper)
    assert_equal ['asset_gatekeeper'], person.roles
    person = Factory(:asset_housekeeper)
    assert_equal ['asset_housekeeper'], person.roles
    person = Factory(:project_administrator)
    assert_equal ['project_administrator'], person.roles
    person = Factory(:pal)
    assert_equal ['pal'], person.roles

    project = person.projects.first
    person.is_asset_gatekeeper = true, project
    assert_equal %w(asset_gatekeeper pal), person.roles.sort

    person.is_admin = true
    assert_equal %w(admin asset_gatekeeper pal), person.roles.sort

    person.is_asset_housekeeper = true, project
    assert_equal %w(admin asset_gatekeeper asset_housekeeper pal), person.roles.sort

    person.is_project_administrator = true, project
    assert_equal %w(admin asset_gatekeeper asset_housekeeper pal project_administrator), person.roles.sort
  end

  test "setting empty array doesn't set role" do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_project_administrator = true, []
      refute person.is_project_administrator_of_any_project?
      refute_includes person.roles, 'project_administrator'

      person.is_pal = true, []
      refute person.is_pal_of_any_project?
      refute_includes person.roles, 'pal'

      person.is_programme_administrator = true, []
      refute person.is_programme_administrator_of_any_programme?
      refute_includes person.roles, 'programme_administrator'
    end
  end

  test 'assign asset_housekeeper role for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person_in_multiple_projects)
      assert person.projects.count > 1

      projects = person.projects[1..3]
      other_project = person.projects.first

      person.is_asset_housekeeper = true, projects
      person.save!
      person.reload
      assert_equal ['asset_housekeeper'], person.roles_for_project(projects[0])
      assert_equal ['asset_housekeeper'], person.roles_for_project(projects[1])
      assert_equal [], person.roles_for_project(other_project)

      person.is_asset_housekeeper = false, projects[0]
      person.save!
      person.reload
      assert_equal [], person.roles_for_project(projects[0])
      assert_equal ['asset_housekeeper'], person.roles_for_project(projects[1])

      person.is_asset_housekeeper = true, projects[0]
      person.save!
      person.reload
      assert_equal ['asset_housekeeper'], person.roles_for_project(projects[0])
      assert_equal ['asset_housekeeper'], person.roles_for_project(projects[1])
    end
  end

  test 'add roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:admin)
      assert_equal 1, person.projects.count
      project = person.projects.first
      assert_equal ['admin'], person.roles
      assert person.can_manage?
      person.add_roles [Seek::Roles::RoleInfo.new(role_name: 'admin'), Seek::Roles::RoleInfo.new(role_name: 'pal', items: project)]
      person.save!
      person.reload
      assert_equal ['pal'].sort, person.roles_for_project(project).sort
      assert person.is_admin?
      assert person.is_pal?(project)
    end
  end

  test 'updating roles with assignment' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person_in_multiple_projects)
      project = person.projects.first

      person.is_admin = true
      person.save!
      person.reload
      assert_equal [], person.roles_for_project(project)
      assert person.is_admin?
      refute person.is_asset_gatekeeper?(project)

      person.is_asset_housekeeper = true, project
      person.save!
      person.reload
      assert_equal ['asset_housekeeper'], person.roles_for_project(project).sort
      assert person.is_admin?
      assert person.is_asset_housekeeper?(project)
      refute person.is_asset_gatekeeper?(project)

      person.is_asset_housekeeper = false, project
      person.is_pal = true, project

      person.save!
      person.reload
      assert_equal ['pal'], person.roles_for_project(project).sort
      assert person.is_admin?
      assert person.is_pal?(project)
      refute person.is_asset_housekeeper?(project)
      refute person.is_asset_gatekeeper?(project)

      project2 = person.projects.last
      person.is_pal = true, project2
      assert person.is_pal?(project)
      refute person.is_asset_housekeeper?(project)
      refute person.is_asset_gatekeeper?(project)
      assert person.is_pal?(project2)
      refute person.is_asset_housekeeper?(project2)
      refute person.is_asset_gatekeeper?(project2)
    end
  end

  test 'non-admin can not change the roles of a person' do
    Factory(:admin) # needed to avoid the next person becoming an admin due to being the first person
    person = Factory(:person)
    project = person.projects.first
    assert_equal [], person.roles_for_project(project)
    User.with_current_user person.user do
      person.is_asset_housekeeper = true, project
      person.is_pal = true, project
      assert person.can_edit?
      refute person.save
      refute person.errors.empty?
      person.reload
      assert_equal [], person.roles_for_project(project)
    end
  end

  test 'projects for role' do
    person = Factory :person_in_multiple_projects
    p1 = person.projects[0]
    p2 = person.projects[1]

    User.with_current_user(Factory(:admin).user) do
      person.is_asset_gatekeeper = true, [p1, p2]
      person.is_pal = true, p1
      person.is_admin = true
    end

    assert_equal [p1], person.projects_for_role('pal')
    assert_equal [p1, p2].sort, person.projects_for_role('asset_gatekeeper').sort
    assert_equal [], person.projects_for_role('asset_housekeeper')
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

      refute person.is_admin?
    end
  end

  test 'is_pal?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_pal = true, project
      person.save!

      assert person.is_pal?(project)
      refute person.is_pal?(other_project)

      person.is_pal = false, project
      person.save!

      refute person.is_pal?(project)
    end
  end

  test 'is_project_administrator?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_project_administrator = true, project
      person.save!

      assert person.is_project_administrator?(project)
      refute person.is_project_administrator?(other_project)

      person.is_project_administrator = false, project
      person.save!

      refute person.is_project_administrator?(project)
    end
  end

  test 'project administrator of multiple projects' do
    person = Factory(:person_in_multiple_projects)
    other_project = Factory(:project)
    projects = person.projects
    assert projects.count > 1
    refute person.is_project_administrator_of_any_project?

    person.is_project_administrator = true, projects
    assert person.is_project_administrator_of_any_project?
    assert person.is_project_administrator?(projects.first)
    assert person.is_project_administrator?(projects[1])
    refute person.is_project_administrator?(other_project)

    person.is_project_administrator = false, projects.first
    refute person.is_project_administrator?(projects.first)
    assert person.is_project_administrator?(projects[1])
    refute person.is_project_administrator?(other_project)
  end

  test 'is project administrator regardless of project' do
    admin = Factory(:admin)
    project_admin = Factory(:project_administrator)
    normal = Factory(:person)

    refute normal.has_role?('project_administrator')
    refute normal.is_project_administrator_of_any_project?

    refute admin.has_role?('project_administrator')
    refute admin.is_project_administrator_of_any_project?

    assert project_admin.has_role?('project_administrator')
    assert project_admin.is_project_administrator_of_any_project?
  end

  test 'is_gatekeeper?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_asset_gatekeeper = true, project
      person.save!

      assert person.is_asset_gatekeeper?(project)
      refute person.is_asset_gatekeeper?(other_project)

      person.is_asset_gatekeeper = false, project
      person.save!

      refute person.is_asset_gatekeeper?(project)
    end
  end

  test 'is_asset_housekeeper?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      project = person.projects.first
      other_project = Factory(:project)
      person.is_asset_housekeeper = true, project
      person.save!

      assert person.is_asset_housekeeper?(project)
      refute person.is_asset_housekeeper?(other_project)

      person.is_asset_housekeeper = false, project
      person.save!

      refute person.is_asset_housekeeper?(project)
    end
  end

  test 'is_asset_housekeeper_of?' do
    asset_housekeeper = Factory(:asset_housekeeper)
    sop = Factory(:sop)
    refute asset_housekeeper.is_asset_housekeeper_of?(sop)

    disable_authorization_checks { sop.projects = asset_housekeeper.projects }

    assert asset_housekeeper.is_asset_housekeeper_of?(sop)
  end

  test 'is_gatekeeper_of?' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop)
    refute gatekeeper.is_asset_gatekeeper_of?(sop)

    disable_authorization_checks { sop.projects = gatekeeper.projects }
    assert gatekeeper.is_asset_gatekeeper_of?(sop)
  end

  test 'order of roles' do
    assert_equal %w(admin pal project_administrator asset_housekeeper asset_gatekeeper programme_administrator), Seek::Roles::Roles.role_names, 'The order of the roles is critical as it determines the mask that is used.'
  end

  test 'factories for roles' do
    User.with_current_user Factory(:admin).user do
      admin = Factory(:admin)
      assert admin.is_admin?
      assert admin.save

      pal = Factory(:pal)
      pal.reload
      assert_equal 2, pal.roles_mask, 'mask should be 2'
      refute pal.projects.empty?
      assert pal.is_pal?(pal.projects.first)
      assert pal.save

      gatekeeper = Factory(:asset_gatekeeper)
      refute gatekeeper.projects.empty?
      assert gatekeeper.is_asset_gatekeeper?(gatekeeper.projects.first)
      assert gatekeeper.save

      asset_housekeeper = Factory(:asset_housekeeper)
      refute asset_housekeeper.projects.empty?
      assert asset_housekeeper.is_asset_housekeeper?(asset_housekeeper.projects.first)
      assert asset_housekeeper.save

      project_administrator = Factory(:project_administrator)
      refute project_administrator.projects.empty?
      assert project_administrator.is_project_administrator?(project_administrator.projects.first)
      assert project_administrator.save

      programme_administrator = Factory(:programme_administrator)
      refute programme_administrator.projects.empty?
      refute programme_administrator.programmes.empty?
      assert programme_administrator.is_programme_administrator_of_any_programme?
    end
  end

  test 'programmes for role' do
    person = Factory(:programme_administrator)
    normal = Factory(:person)

    assert_equal person.programmes, person.programmes_for_role('programme_administrator')
    assert_empty normal.programmes_for_role('programme_administrator')
  end

  test 'Person.pals' do
    admin = Factory(:admin)
    normal = Factory(:person)
    pal = Factory(:pal)
    pal2 = Factory(:project_administrator)
    pal2.is_pal = true, pal2.projects.first
    pal2.save!

    pals = Person.pals

    assert pals.include?(pal)
    assert pals.include?(pal2)
    refute pals.include?(normal)
  end

  test 'Person.admins' do
    admin = Factory(:admin)
    admin2 = Factory(:project_administrator)
    admin2.is_admin = true
    admin2.save!
    normal = Factory(:person)

    admins = Person.admins
    assert admins.include?(admin)
    assert admins.include?(admin2)
    refute admins.include?(normal)
  end

  test 'Person.gatekeepers' do
    normal = Factory(:person)
    gatekeeper = Factory(:asset_gatekeeper)
    gatekeeper2 = Factory(:project_administrator)
    gatekeeper2.is_asset_gatekeeper = true, gatekeeper2.projects.first
    gatekeeper2.save!

    gatekeepers = Person.asset_gatekeepers
    assert gatekeepers.include?(gatekeeper)
    assert gatekeepers.include?(gatekeeper2)
    refute gatekeepers.include?(normal)
  end

  test 'Person.asset_housekeeper' do
    normal = Factory(:person)
    asset_housekeeper = Factory(:asset_housekeeper)
    asset_housekeeper2 = Factory(:project_administrator)
    asset_housekeeper2.is_asset_housekeeper = true, asset_housekeeper2.projects.first
    asset_housekeeper2.save!

    asset_housekeepers = Person.asset_housekeepers
    assert asset_housekeepers.include?(asset_housekeeper)
    refute asset_housekeepers.include?(normal)
  end

  test 'Person.project_administrators' do
    normal = Factory(:person)
    project_administrator = Factory(:project_administrator)
    project_administrator2 = Factory(:asset_gatekeeper)
    project_administrator2.is_project_administrator = true, project_administrator2.projects.first
    project_administrator2.save!

    project_administrators = Person.project_administrators
    assert project_administrators.include?(project_administrator)
    assert project_administrators.include?(project_administrator2)
    refute project_administrators.include?(normal)
  end

  test 'is_in_any_gatekept_projects?' do
    normal = Factory(:person)
    gatekeeper = Factory(:asset_gatekeeper)
    refute normal.is_in_any_gatekept_projects?

    another_normal = Factory :person,
                             group_memberships: [Factory(:group_membership,
                                                         work_group: gatekeeper.group_memberships.first.work_group)]
    assert another_normal.is_in_any_gatekept_projects?
  end

  test 'Person.programme_administrators' do
    programme_admin = Factory(:person)
    normal = Factory(:person)
    programme = Factory(:programme)
    programme_admin.is_programme_administrator = true, programme
    programme_admin.save!

    admins = Person.programme_administrators
    assert_kind_of ActiveRecord::Relation, admins
    assert_includes admins, programme_admin
    refute_includes admins, normal
  end

  test 'programme administrator' do
    person = Factory(:person)
    programme = Factory(:programme)
    other_programme = Factory(:programme)
    refute person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programme)
    refute person.is_programme_administrator?(other_programme)

    person.is_programme_administrator = true, programme
    assert person.is_programme_administrator_of_any_programme?
    assert person.is_programme_administrator?(programme)
    refute person.is_programme_administrator?(other_programme)
  end

  test 'programme administrator multiple programmes' do
    person = Factory(:person)
    programmes = [Factory(:programme), Factory(:programme)]
    other_programme = Factory(:programme)
    refute person.is_programme_administrator_of_any_programme?

    person.is_programme_administrator = true, programmes
    assert person.is_programme_administrator_of_any_programme?
    assert person.is_programme_administrator?(programmes[0])
    assert person.is_programme_administrator?(programmes[1])
    refute person.is_programme_administrator?(other_programme)

    person.is_programme_administrator = false, programmes[0]
    person.is_programme_administrator = true, other_programme
    assert person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programmes[0])
    assert person.is_programme_administrator?(programmes[1])
    assert person.is_programme_administrator?(other_programme)

    person.save!
    person = Person.find(person.id)
    assert person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programmes[0])
    assert person.is_programme_administrator?(programmes[1])
    assert person.is_programme_administrator?(other_programme)
  end

  test 'role info' do
    proj = Factory(:project)
    info = Seek::Roles::RoleInfo.new(role_name: 'project_administrator', items: [proj])
    assert_equal 'project_administrator', info.role_name
    assert_equal [proj], info.items

    info = Seek::Roles::RoleInfo.new(role_name: 'project_administrator', items: proj)
    assert_equal 'project_administrator', info.role_name
    assert_equal [proj], info.items

    info = Seek::Roles::RoleInfo.new(role_name: 'project_administrator')
    assert_equal 'project_administrator', info.role_name
    assert_equal [], info.items

    assert_raise(Seek::Roles::UnknownRoleException) do
      Seek::Roles::RoleInfo.new(role_name: 'frog')
    end
  end

  test 'items_for_person_and_role' do
    person = Factory(:programme_administrator)
    programmes = person.programmes
    result = Seek::Roles::ProgrammeRelatedRoles.instance.items_for_person_and_role(person, 'programme_administrator')
    assert_equal programmes.sort, result.sort

    # needs to be an ActiveRecord::Relation so that it can be extended with scopes and other query clauses
    assert_kind_of ActiveRecord::Relation, result
    assert_kind_of ActiveRecord::Relation, person.administered_programmes

    # no roles but should not just return an empty array
    person = Factory(:person)
    result = Seek::Roles::ProgrammeRelatedRoles.instance.items_for_person_and_role(person, 'programme_administrator')
    assert_kind_of ActiveRecord::Relation, result
    assert_kind_of ActiveRecord::Relation, person.administered_programmes

    # also for admin
    person = Factory(:admin)
    assert_kind_of ActiveRecord::Relation, person.administered_programmes
  end

  test "nil roles mask doesn't indicate administrator" do
    p = Factory(:person)
    p.roles_mask = nil
    refute p.is_admin?
    disable_authorization_checks { p.save! }
    p.reload
    refute p.is_admin?
    refute_includes(Person.admins, p)
  end
end
