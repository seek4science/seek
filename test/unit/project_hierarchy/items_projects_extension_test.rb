require 'test_helper'
require 'integration/project_hierarchy/project_hierarchy_test_helper'
class ItemsProjectsExtensionTest < ActiveSupport::TestCase
  include ProjectHierarchyTestHelper

  test "projects and descendants" do
    assay = Factory :experimental_assay, :study => Factory(:study, :investigation => Factory(:investigation, :projects => [@proj]))
    assert_equal [@proj, @proj_child1, @proj_child2].sort, assay.projects_and_descendants.sort

    study = Factory(:study, :investigation => Factory(:investigation, :projects => [@proj]))
    assert_equal [@proj, @proj_child1, @proj_child2].sort, study.projects_and_descendants.sort
  end

  test "projects and ancestors" do
    assay = Factory :experimental_assay, :study => Factory(:study, :investigation => Factory(:investigation, :projects => [@proj_child1]))
    assert_equal [@proj, @proj_child1].sort, assay.projects_and_ancestors.sort

    study = Factory(:study, :investigation => Factory(:investigation, :projects => [@proj_child1]))
    assert_equal [@proj, @proj_child1].sort, study.projects_and_ancestors.sort
  end
end