require 'test_helper'
require 'project_hierarchy_test_helper'
class AdminDefinedRolesExtensionTest < ActiveSupport::TestCase
  include ProjectHierarchyTestHelper

  test 'admin defined roles in projects should be also the roles in sub projects' do
    person = new_person_with_hierarchical_projects
    person.work_groups.create project: @proj, institution: Factory(:institution)
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert_equal [@proj, @proj_child1, @proj_child2].sort, person.projects_and_descendants.sort

    [@proj, @proj_child1, @proj_child2].each do |p|
      assert !person.is_asset_housekeeper?(p)
      assert !person.is_project_administrator?(p)
      assert !person.is_pal?(p)
      assert !person.is_asset_gatekeeper?(p)

      assert p.asset_housekeepers.empty?
      assert p.project_administrators.empty?
      assert p.pals.empty?
      assert p.asset_gatekeepers.empty?
    end

    person.is_asset_housekeeper = true, @proj
    person.is_project_administrator = true, @proj
    person.is_pal = true, @proj
    person.is_asset_gatekeeper = true, @proj

    disable_authorization_checks do
      person.save!
    end
    person.reload

    [@proj_child1].each do |p|
      assert person.is_asset_housekeeper?(p)
      assert person.is_project_administrator?(p)
      assert person.is_pal?(p)
      assert person.is_asset_gatekeeper?(p)

      assert_equal [person], p.asset_housekeepers
      assert_equal [person], p.project_administrators
      assert_equal [person], p.pals
      assert_equal [person], p.asset_gatekeepers
    end

    # test assigning roles to admins
    person.roles_mask = Seek::Roles::Roles.instance.mask_for_role('admin')
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert person.is_admin?

    person.is_admin = true
    person.is_asset_housekeeper = true, @proj
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert person.is_admin?
    [@proj, @proj_child1, @proj_child2].each do |p|
      assert person.is_asset_housekeeper?(p)
      assert_equal [person], p.asset_housekeepers
    end
  end
end
