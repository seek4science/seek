require 'test_helper'
require 'integration/project_hierarchy/project_hierarchy_test_helper'
class StudyExtensionTest < ActionController::IntegrationTest
  include ProjectHierarchyTestHelper
  def setup
      skip("tests are skipped as projects are NOT hierarchical") unless Seek::Config.project_hierarchy_enabled
      initialize_hierarchical_projects
  end

  test "projects and descendants" do
       study =  Factory(:study, :investigation => Factory(:investigation, :projects => [@proj]))
       assert_equal [@proj, @proj_child1, @proj_child2].sort, study.projects_and_descendants.sort
  end

end