require 'test_helper'
require 'integration/project_hierarchy/project_hierarchy_test_helper'
class SharingPolicyWithHierarchyTest < ActionController::IntegrationTest
  include ProjectHierarchyTestHelper

  def setup
    skip("tests are skipped as projects are NOT hierarchical") unless Seek::Config.project_hierarchy_enabled
    initialize_hierarchical_projects
  end

  test "items shared in parent project are also shared with same policy in child projects" do
    person_in_parent = Factory :person, :work_groups => [Factory(:work_group, :project_id => @proj.id)]
    person_in_child1 = Factory :person, :work_groups => [Factory(:work_group, :project_id => @proj_child1.id)]
    person_in_child2 = Factory :person, :work_groups => [Factory(:work_group, :project_id => @proj_child2.id)]
    df = Factory :data_file, :policy => Factory(:all_sysmo_viewable_policy), :projects => [@proj]
    assert df.can_view?(person_in_parent)
    assert df.can_view?(person_in_child1)
    assert df.can_view?(person_in_child2)
  end

end