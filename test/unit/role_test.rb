require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  def setup
    User.current_user = FactoryBot.create(:admin).user
  end

  test 'cannot add a role with a project the person is not a member of' do
    person = FactoryBot.create(:person)
    project1 = person.projects.first
    project2 = FactoryBot.create(:project)

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
    FactoryBot.create(:admin) # prevents this following person also becoming an admin due to being first
    person = FactoryBot.create(:project_administrator)
    project = person.projects.first

    assert person.is_project_administrator?(project)
    assert person.is_project_administrator_of_any_project?

    assert_difference('Role.count', -1) do
      person.work_groups = []
      person.save!
    end

    person.reload

    refute_includes person.projects, project, 'should no longer be a member of that project'

    refute person.is_project_administrator?(project), 'should no longer be project administrator for that project'
    refute person.is_project_administrator_of_any_project?, 'should no longer be a project administrator at all'
  end

  test 'unassign_role' do
    person = FactoryBot.create(:programme_administrator)
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

    person.unassign_role('project_administrator', project)

    assert person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    assert person.is_asset_gatekeeper?(project)
    assert person.is_pal?(project)
    assert person.is_admin?

    person.unassign_role('asset_gatekeeper', [project])

    assert person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    assert person.is_pal?(project)
    assert person.is_admin?

    person.unassign_role('pal', [project])

    assert person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_pal?(project)
    assert person.is_admin?

    person.unassign_role('programme_administrator', person.programmes)

    refute person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_pal?(project)
    assert person.is_admin?

    person.unassign_role('admin')

    refute person.is_programme_administrator?(person.programmes.first)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_pal?(project)
    refute person.is_admin?

    person = FactoryBot.create(:programme_administrator)
    project = person.projects.first
    person.is_pal = true, project
    person.save!
    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_pal?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_admin?

    person.unassign_role(:asset_gatekeeper, [])

    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_pal?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_admin?

    person.unassign_role('admin', [])

    assert person.is_programme_administrator?(person.programmes.first)
    assert person.is_pal?(project)
    refute person.is_asset_gatekeeper?(project)
    refute person.is_admin?
  end

  test 'repeatedly removing role' do
    person = FactoryBot.create(:programme_administrator)
    programme1 = person.programmes.first
    programme2 = FactoryBot.create(:programme)

    person.is_programme_administrator = true, programme2
    person.is_asset_gatekeeper = true, person.projects.first

    assert person.is_programme_administrator_of_any_programme?
    assert person.is_programme_administrator?(programme1)
    assert person.is_programme_administrator?(programme2)

    assert_difference('Role.count', -1) do
      person.unassign_role('programme_administrator', programme1)
    end

    assert person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programme1)
    assert person.is_programme_administrator?(programme2)

    assert_difference('Role.count', -1) do
      person.unassign_role('programme_administrator', programme2)
    end

    refute person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programme1)
    refute person.is_programme_administrator?(programme2)
    assert_no_difference('Role.count') do
      person.unassign_role('programme_administrator', programme2)
    end

    refute person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programme1)
    refute person.is_programme_administrator?(programme2)

  end

  test 'destroying a person destroys the project role details' do
    person = FactoryBot.create(:asset_housekeeper)
    User.with_current_user(FactoryBot.create(:admin).user) do
      person.is_pal = true, person.projects.first
      person.save!
    end

    assert_difference('Role.count', -2) do
      person.destroy
    end
  end

  test 'roles' do
    person = FactoryBot.create(:admin)
    assert_equal ['admin'], person.role_names

    person = FactoryBot.create(:asset_gatekeeper)
    assert_equal ['asset_gatekeeper'], person.role_names
    person = FactoryBot.create(:asset_housekeeper)
    assert_equal ['asset_housekeeper'], person.role_names
    person = FactoryBot.create(:project_administrator)
    assert_equal ['project_administrator'], person.role_names
    person = FactoryBot.create(:pal)
    assert_equal ['pal'], person.role_names

    project = person.projects.first
    person.is_asset_gatekeeper = true, project
    assert_equal %w(asset_gatekeeper pal), person.role_names.sort

    person.is_admin = true
    assert_equal %w(admin asset_gatekeeper pal), person.role_names.sort

    person.is_asset_housekeeper = true, project
    assert_equal %w(admin asset_gatekeeper asset_housekeeper pal), person.role_names.sort

    person.is_project_administrator = true, project
    assert_equal %w(admin asset_gatekeeper asset_housekeeper pal project_administrator), person.role_names.sort
  end

  test "setting empty array doesn't set role" do
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person)
      person.is_project_administrator = true, []
      refute person.is_project_administrator_of_any_project?
      refute_includes person.role_names, 'project_administrator'

      person.is_pal = true, []
      refute person.is_pal_of_any_project?
      refute_includes person.role_names, 'pal'

      person.is_programme_administrator = true, []
      refute person.is_programme_administrator_of_any_programme?
      refute_includes person.role_names, 'programme_administrator'
    end
  end

  test 'assign asset_housekeeper role for a person' do
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person_in_multiple_projects)
      assert person.projects.count > 1

      projects = person.projects[1..3]
      other_project = person.projects.first

      person.is_asset_housekeeper = true, projects
      person.save!
      person.reload
      assert_equal ['asset_housekeeper'], person.scoped_roles(projects[0]).map(&:key)
      assert_equal ['asset_housekeeper'], person.scoped_roles(projects[1]).map(&:key)
      assert_equal [], person.scoped_roles(other_project).map(&:key)

      person.is_asset_housekeeper = false, projects[0]
      person.save!
      person.reload
      assert_equal [], person.scoped_roles(projects[0]).map(&:key)
      assert_equal ['asset_housekeeper'], person.scoped_roles(projects[1]).map(&:key)

      person.is_asset_housekeeper = true, projects[0]
      person.save!
      person.reload
      assert_equal ['asset_housekeeper'], person.scoped_roles(projects[0]).map(&:key)
      assert_equal ['asset_housekeeper'], person.scoped_roles(projects[1]).map(&:key)
    end
  end

  test 'add roles for a person' do
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:admin)
      assert_equal 1, person.projects.count
      project = person.projects.first
      assert_equal ['admin'], person.role_names
      assert person.can_manage?
      person.assign_role('admin')
      person.assign_role('pal', project)
      person.save!
      person.reload
      assert_equal ['pal'].sort, person.scoped_roles(project).sort.map(&:key)
      assert person.is_admin?
      assert person.is_pal?(project)
    end
  end

  test 'updating roles with assignment' do
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person_in_multiple_projects)
      project = person.projects.first

      person.is_admin = true
      person.save!
      person.reload
      assert_equal [], person.scoped_roles(project).map(&:key)
      assert person.is_admin?
      refute person.is_asset_gatekeeper?(project)

      person.is_asset_housekeeper = true, project
      person.save!
      person.reload
      assert_equal ['asset_housekeeper'], person.scoped_roles(project).sort.map(&:key)
      assert person.is_admin?
      assert person.is_asset_housekeeper?(project)
      refute person.is_asset_gatekeeper?(project)

      person.is_asset_housekeeper = false, project
      person.is_pal = true, project

      person.save!
      person.reload
      assert_equal ['pal'], person.scoped_roles(project).sort.map(&:key)
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
    FactoryBot.create(:admin) # needed to avoid the next person becoming an admin due to being the first person
    person = FactoryBot.create(:person)
    project = person.projects.first
    assert_equal [], person.scoped_roles(project).map(&:key)
    User.with_current_user person.user do
      assert person.can_edit?
      assert_no_difference('Role.count') do
        person.is_asset_housekeeper = true, project
        person.is_pal = true, project
      end
      refute person.valid?
      refute person.roles.all? { |r| r.errors.empty? }
      person.reload
      assert_equal [], person.scoped_roles(project).map(&:key)
    end
  end

  test 'projects for role' do
    person = FactoryBot.create :person_in_multiple_projects
    p1 = person.projects[0]
    p2 = person.projects[1]

    User.with_current_user(FactoryBot.create(:admin).user) do
      person.is_asset_gatekeeper = true, [p1, p2]
      person.is_pal = true, p1
      person.is_admin = true
    end

    assert_equal [p1], person.projects_for_role('pal')
    assert_equal [p1, p2].sort, person.projects_for_role('asset_gatekeeper').sort
    assert_equal [], person.projects_for_role('asset_housekeeper')
  end

  test 'is_admin?' do
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person)

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
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person)
      project = person.projects.first
      other_project = FactoryBot.create(:project)
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
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person)
      project = person.projects.first
      other_project = FactoryBot.create(:project)
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
    person = FactoryBot.create(:person_in_multiple_projects)
    other_project = FactoryBot.create(:project)
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
    admin = FactoryBot.create(:admin)
    project_admin = FactoryBot.create(:project_administrator)
    normal = FactoryBot.create(:person)

    refute normal.has_role?('project_administrator')
    refute normal.is_project_administrator_of_any_project?

    refute admin.has_role?('project_administrator')
    refute admin.is_project_administrator_of_any_project?

    assert project_admin.has_role?('project_administrator')
    assert project_admin.is_project_administrator_of_any_project?
  end

  test 'is_gatekeeper?' do
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person)
      project = person.projects.first
      other_project = FactoryBot.create(:project)
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
    User.with_current_user FactoryBot.create(:admin).user do
      person = FactoryBot.create(:person)
      project = person.projects.first
      other_project = FactoryBot.create(:project)
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
    asset_housekeeper = FactoryBot.create(:asset_housekeeper)
    sop = FactoryBot.create(:sop)
    refute asset_housekeeper.is_asset_housekeeper_of?(sop)

    disable_authorization_checks { sop.projects = asset_housekeeper.projects }

    assert asset_housekeeper.is_asset_housekeeper_of?(sop)
  end

  test 'is_gatekeeper_of?' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    sop = FactoryBot.create(:sop)
    refute gatekeeper.is_asset_gatekeeper_of?(sop)

    disable_authorization_checks { sop.projects = gatekeeper.projects }
    assert gatekeeper.is_asset_gatekeeper_of?(sop)
  end

  test 'locale for roles' do
    #it's important the role name constants map the the locale key
    assert I18n.exists?(:pal)
    assert I18n.exists?(:project_administrator)
    assert I18n.exists?(:programme_administrator)
    assert I18n.exists?(:asset_gatekeeper)
    assert I18n.exists?(:asset_housekeeper)
  end

  test 'factories for roles' do
    User.with_current_user FactoryBot.create(:admin).user do
      admin = FactoryBot.create(:admin)
      assert admin.is_admin?
      assert admin.save

      pal = FactoryBot.create(:pal)
      pal.reload
      refute pal.projects.empty?
      assert pal.is_pal?(pal.projects.first)
      assert pal.save

      gatekeeper = FactoryBot.create(:asset_gatekeeper)
      refute gatekeeper.projects.empty?
      assert gatekeeper.is_asset_gatekeeper?(gatekeeper.projects.first)
      assert gatekeeper.save

      asset_housekeeper = FactoryBot.create(:asset_housekeeper)
      refute asset_housekeeper.projects.empty?
      assert asset_housekeeper.is_asset_housekeeper?(asset_housekeeper.projects.first)
      assert asset_housekeeper.save

      project_administrator = FactoryBot.create(:project_administrator)
      refute project_administrator.projects.empty?
      assert project_administrator.is_project_administrator?(project_administrator.projects.first)
      assert project_administrator.save

      programme_administrator = FactoryBot.create(:programme_administrator)
      refute programme_administrator.projects.empty?
      refute programme_administrator.programmes.empty?
      assert programme_administrator.is_programme_administrator_of_any_programme?
    end
  end

  test 'programmes for role' do
    person = FactoryBot.create(:programme_administrator)
    normal = FactoryBot.create(:person)

    assert_equal person.programmes, person.programmes_for_role('programme_administrator')
    assert_empty normal.programmes_for_role('programme_administrator')
  end

  test 'Person.pals' do
    admin = FactoryBot.create(:admin)
    normal = FactoryBot.create(:person)
    pal = FactoryBot.create(:pal)
    pal2 = FactoryBot.create(:project_administrator)
    pal2.is_pal = true, pal2.projects.first
    pal2.save!

    pals = Person.pals

    assert pals.include?(pal)
    assert pals.include?(pal2)
    refute pals.include?(normal)
  end

  test 'Person.admins' do
    admin = FactoryBot.create(:admin)
    admin2 = FactoryBot.create(:project_administrator)
    admin2.is_admin = true
    admin2.save!
    normal = FactoryBot.create(:person)

    admins = Person.admins
    assert admins.include?(admin)
    assert admins.include?(admin2)
    refute admins.include?(normal)
  end

  test 'Person.gatekeepers' do
    normal = FactoryBot.create(:person)
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    gatekeeper2 = FactoryBot.create(:project_administrator)
    gatekeeper2.is_asset_gatekeeper = true, gatekeeper2.projects.first
    gatekeeper2.save!

    gatekeepers = Person.asset_gatekeepers
    assert gatekeepers.include?(gatekeeper)
    assert gatekeepers.include?(gatekeeper2)
    refute gatekeepers.include?(normal)
  end

  test 'Person.asset_housekeeper' do
    normal = FactoryBot.create(:person)
    asset_housekeeper = FactoryBot.create(:asset_housekeeper)
    asset_housekeeper2 = FactoryBot.create(:project_administrator)
    asset_housekeeper2.is_asset_housekeeper = true, asset_housekeeper2.projects.first
    asset_housekeeper2.save!

    asset_housekeepers = Person.asset_housekeepers
    assert asset_housekeepers.include?(asset_housekeeper)
    refute asset_housekeepers.include?(normal)
  end

  test 'Person.project_administrators' do
    normal = FactoryBot.create(:person)
    project_administrator = FactoryBot.create(:project_administrator)
    project_administrator2 = FactoryBot.create(:asset_gatekeeper)
    project_administrator2.is_project_administrator = true, project_administrator2.projects.first
    project_administrator2.save!

    project_administrators = Person.project_administrators
    assert project_administrators.include?(project_administrator)
    assert project_administrators.include?(project_administrator2)
    refute project_administrators.include?(normal)
  end

  test 'is_in_any_gatekept_projects?' do
    normal = FactoryBot.create(:person)
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    refute normal.is_in_any_gatekept_projects?

    another_normal = FactoryBot.create :person,
                             group_memberships: [FactoryBot.create(:group_membership,
                                                         work_group: gatekeeper.group_memberships.first.work_group)]
    assert another_normal.is_in_any_gatekept_projects?
  end

  test 'Person.programme_administrators' do
    programme_admin = FactoryBot.create(:person)
    normal = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme)
    programme_admin.is_programme_administrator = true, programme
    programme_admin.save!

    admins = Person.programme_administrators
    assert_kind_of ActiveRecord::Relation, admins
    assert_includes admins, programme_admin
    refute_includes admins, normal
  end

  test 'programme administrator' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme)
    other_programme = FactoryBot.create(:programme)
    refute person.is_programme_administrator_of_any_programme?
    refute person.is_programme_administrator?(programme)
    refute person.is_programme_administrator?(other_programme)

    person.is_programme_administrator = true, programme
    assert person.is_programme_administrator_of_any_programme?
    assert person.is_programme_administrator?(programme)
    refute person.is_programme_administrator?(other_programme)
  end

  test 'programme administrator multiple programmes' do
    person = FactoryBot.create(:person)
    programmes = [FactoryBot.create(:programme), FactoryBot.create(:programme)]
    other_programme = FactoryBot.create(:programme)
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

  test 'items_for_person_and_role' do
    person = FactoryBot.create(:programme_administrator)
    programmes = person.programmes
    result = person.programmes_for_role('programme_administrator')
    assert_equal programmes.sort, result.sort

    # needs to be an ActiveRecord::Relation so that it can be extended with scopes and other query clauses
    assert_kind_of ActiveRecord::Relation, result
    assert_kind_of ActiveRecord::Relation, person.administered_programmes

    # no roles but should not just return an empty array
    person = FactoryBot.create(:person)
    result = person.programmes_for_role('programme_administrator')
    assert_kind_of ActiveRecord::Relation, result
    assert_kind_of ActiveRecord::Relation, person.administered_programmes

    # also for admin
    person = FactoryBot.create(:admin)
    assert_kind_of ActiveRecord::Relation, person.administered_programmes
  end

  test 'fire update auth table job when project role created' do
    person = FactoryBot.create(:person)
    with_config_value :auth_lookup_enabled, true do
      assert_enqueued_with(job: AuthLookupUpdateJob) do
        assert_difference('AuthLookupUpdateQueue.count', 1) do
          Role.create!(person: person, scope: person.projects.first, role_type: RoleType.find_by_key(:project_administrator))
        end
      end
    end
  end

  test 'fire update auth table job when project role destroyed' do
    person = FactoryBot.create(:person)
    role = Role.create!(person: person, scope: person.projects.first, role_type: RoleType.find_by_key(:project_administrator))
    with_config_value :auth_lookup_enabled, true do
      assert_enqueued_with(job: AuthLookupUpdateJob) do
        assert_difference('AuthLookupUpdateQueue.count', 1) do
          role.destroy
        end
      end
    end
  end

  test 'validate person must exist when creating project role' do
    person = FactoryBot.create(:person)
    role = Role.new(scope: person.projects.first, role_type: RoleType.find_by_key(:project_administrator))
    refute role.valid?
    role.person = person
    assert role.valid?
  end

  test 'validate project must exist when creating project role' do
    person = FactoryBot.create(:person)
    role = Role.new(person: person, role_type: RoleType.find_by_key(:project_administrator))
    refute role.valid?
    role.scope = person.projects.first
    assert role.valid?
  end

  test 'validate project must belong to person when creating project role' do
    person = FactoryBot.create(:person)
    project = FactoryBot.create(:project)
    role = Role.new(person: person, scope: project, role_type: RoleType.find_by_key(:project_administrator))
    refute role.valid?
    role.scope = person.projects.first
    assert role.valid?
    role.save!
  end

  test 'fire update auth table job when programme role created' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme)
    with_config_value :auth_lookup_enabled, true do
      assert_enqueued_with(job: AuthLookupUpdateJob) do
        assert_difference('AuthLookupUpdateQueue.count', 1) do
          Role.create!(person: person, scope: programme, role_type: RoleType.find_by_key(:programme_administrator))
        end
      end
    end
  end

  test 'fire update auth table job when programme role destroyed' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme, projects: person.projects)
    role = Role.create!(person: person, scope: programme, role_type: RoleType.find_by_key(:programme_administrator))
    with_config_value :auth_lookup_enabled, true do
      assert_enqueued_with(job: AuthLookupUpdateJob) do
        assert_difference('AuthLookupUpdateQueue.count', 1) do
          role.destroy
        end
      end
    end
  end

  test 'validate person must exist when creating programme role' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme, projects: person.projects)
    role = Role.new(scope: programme, role_type: RoleType.find_by_key(:programme_administrator))
    refute role.valid?
    role.person = person
    assert role.valid?
  end

  test 'validate programme must exist when creating programme role' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme, projects: person.projects)
    role = Role.new(person: person, role_type: RoleType.find_by_key(:programme_administrator))
    refute role.valid?
    role.scope = programme
    role.valid?
    assert role.valid?
  end

  test 'admins can grant admin roles' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:admin)
    User.with_current_user(role_granter.user) do
      assert_difference('Role.count', 1) do
        person.is_admin = true
      end
    end
  end

  test 'non-admins cannot grant admin roles' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:person)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_admin = true
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant system roles')
    end
  end

  test 'project admins can grant project roles' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:project_administrator, project: person.projects.first)
    User.with_current_user(role_granter.user) do
      assert_difference('Role.count', 1) do
        person.is_project_administrator = true, role_granter.projects.first
      end
    end
  end

  test 'project admins cannot grant project roles to people not in the project' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:project_administrator)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_project_administrator = true, role_granter.projects.first
      end
      assert person.roles.last.errors.added?(:person, 'does not belong to this Project')
    end
  end

  test 'system admins cannot grant project roles to people not in the project' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:admin)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_project_administrator = true, role_granter.projects.first
      end
      assert person.roles.last.errors.added?(:person, 'does not belong to this Project')
    end
  end

  test 'project admins cannot grant non-project roles' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:project_administrator, project: person.projects.first)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_admin = true
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant system roles')
    end
  end

  test 'non-project admins cannot grant project roles' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:person, project: person.projects.first)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_project_administrator = true, role_granter.projects.first
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant roles in this Project')
    end
  end

  test 'project admins cannot grant project roles to projects they are not a member of' do
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:project_administrator, project: person.projects.first)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_project_administrator = true, FactoryBot.create(:project)
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant roles in this Project')
    end
  end

  test 'programme admins can grant programme roles' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    person = FactoryBot.create(:person, project: project)
    role_granter = FactoryBot.create(:programme_administrator, project: project)
    User.with_current_user(role_granter.user) do
      assert_difference('Role.count', 1) do
        person.is_programme_administrator = true, role_granter.programmes.first
      end
    end
  end

  test 'programme admins CAN grant programme roles to people not in the programme' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    person = FactoryBot.create(:person)
    role_granter = FactoryBot.create(:programme_administrator, project: project)
    refute_includes programme.people, person
    User.with_current_user(role_granter.user) do
      assert_difference('Role.count', 1) do
        person.is_programme_administrator = true, role_granter.programmes.first
      end
    end
  end

  test 'programme admins cannot grant non-programme roles' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    person = FactoryBot.create(:person, project: project)
    role_granter = FactoryBot.create(:programme_administrator, project: project)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_admin = true
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant system roles')
    end
  end

  test 'non-programme admins cannot grant programme roles' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    person = FactoryBot.create(:person, project: project)
    role_granter = FactoryBot.create(:person, project: project)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_programme_administrator = true, role_granter.programmes.first
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant roles in this Programme')
    end
  end

  test 'programme admins cannot grant programme roles to programmes they are not a member of' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    person = FactoryBot.create(:person, project: project)
    role_granter = FactoryBot.create(:programme_administrator, project: project)
    User.with_current_user(role_granter.user) do
      assert_no_difference('Role.count') do
        person.is_programme_administrator = true, FactoryBot.create(:programme)
      end
      assert person.roles.last.errors.added?(:base, 'You are not authorized to grant roles in this Programme')
    end
  end

  test 'role type count' do
    assert RoleType.all.count > 0
    assert RoleType.for_system.count > 0
    assert RoleType.for_projects.count > 0
    assert RoleType.for_programmes.count > 0
  end

  test 'fetching role types' do
    assert RoleType.find_by_key('admin')
    assert RoleType.find_by_key(:admin)
    assert_nil RoleType.find_by_key('badmin')
    assert RoleType.find_by_key!('admin')
    assert RoleType.find_by_key!(:admin)
    assert_raises(Seek::Roles::UnknownRoleException) do
      assert_nil RoleType.find_by_key!('hello')
    end

    assert_equal 'admin', RoleType.find_by_id(1).key
    assert_equal 'pal', RoleType.find_by_id(2).key
    assert_equal 'project_administrator', RoleType.find_by_id(4).key
    assert_equal 'asset_housekeeper', RoleType.find_by_id(8).key
    assert_equal 'asset_gatekeeper', RoleType.find_by_id(16).key
    assert_equal 'programme_administrator', RoleType.find_by_id(32).key
    assert_nil RoleType.find_by_id(3)
  end

  test 'role type title' do
    assert_equal 'Project administrator', RoleType.find_by_key('project_administrator').title
    assert_equal 'Asset gatekeeper', RoleType.find_by_key('asset_gatekeeper').title
  end
end
