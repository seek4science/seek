require 'test_helper'
require 'integration/project_hierarchy/project_hierarchy_test_helper'
class PersonExtensionTest < ActionController::IntegrationTest
  include ProjectHierarchyTestHelper
  def setup
      skip("tests are skipped as projects are NOT hierarchical") unless Seek::Config.project_hierarchy_enabled
      initialize_hierarchical_projects
  end

  test "person's projects include direct projects and parent projects" do
      parent_proj = Factory :project
      proj = Factory :project, :parent_id => parent_proj.id
      p = Factory(:brand_new_person, :work_groups => [Factory(:work_group, :project => proj)])
      assert_equal [parent_proj, proj].map(&:id).sort, p.projects.map(&:id).sort
  end

end