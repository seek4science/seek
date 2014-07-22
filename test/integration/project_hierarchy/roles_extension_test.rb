require 'test_helper'
require 'integration/project_hierarchy/project_hierarchy_test_helper'
class RolesExtensionTest < ActionController::IntegrationTest
  include ProjectHierarchyTestHelper
  def setup
        skip("tests are skipped as projects are NOT hierarchical") unless Seek::Config.project_hierarchy_enabled
        initialize_hierarchical_projects
  end



test "admin defined roles in projects should be also the roles in sub projects" do
    person = new_person_with_hierarchical_projects
    person.work_groups.create :project => @proj, :institution => Factory(:institution)
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert_equal [@proj, @proj_child1, @proj_child2].sort, person.projects_and_descendants.sort

    [@proj, @proj_child1, @proj_child2].each do |p|
      assert_equal false, person.is_asset_manager?(p)
      assert_equal false, person.is_project_manager?(p)
      assert_equal false, person.is_pal?(p)
      assert_equal false, person.is_gatekeeper?(p)

      assert p.asset_managers.empty?
      assert p.project_managers.empty?
      assert p.pals.empty?
      assert p.gatekeepers.empty?
    end

    person.roles = [["asset_manager", @proj.id.to_s], ["project_manager", @proj.id.to_s], ["pal", @proj.id.to_s], ["gatekeeper", @proj.id.to_s]]
    disable_authorization_checks do
      person.save!
    end
    person.reload

    [@proj, @proj_child1, @proj_child2].each do |p|
      assert_equal true, person.is_asset_manager?(p)
      assert_equal true, person.is_project_manager?(p)
      assert_equal true, person.is_pal?(p)
      assert_equal true, person.is_gatekeeper?(p)

      assert_equal [person], p.asset_managers
      assert_equal [person], p.project_managers
      assert_equal [person], p.pals
      assert_equal [person], p.gatekeepers
    end

    # test assigning roles to admins
    person.roles_mask = Person.mask_for_role("admin")
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert person.is_admin?

    person.roles = [["admin"], ["asset_manager", @proj.id.to_s]]
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert person.is_admin?
    [@proj, @proj_child1, @proj_child2].each do |p|
      assert_equal true, person.is_asset_manager?(p)
      assert_equal [person], p.asset_managers
    end

end
end