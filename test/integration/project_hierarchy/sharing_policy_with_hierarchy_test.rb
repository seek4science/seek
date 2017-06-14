require 'test_helper'
require 'project_hierarchy_test_helper'

class SharingPolicyWithHierarchyTest < ActionDispatch::IntegrationTest
  include ProjectHierarchyTestHelper

  test 'items shared in parent project are also shared with same policy in child projects' do
    person_in_parent = Factory :person, work_groups: [Factory(:work_group, project_id: @proj.id)]
    person_in_child1 = Factory :person, work_groups: [Factory(:work_group, project_id: @proj_child1.id)]
    person_in_child2 = Factory :person, work_groups: [Factory(:work_group, project_id: @proj_child2.id)]
    df = Factory :data_file, policy: Factory(:all_sysmo_viewable_policy), projects: [@proj]
    assert df.can_view?(person_in_parent)
    assert df.can_view?(person_in_child1)
    assert df.can_view?(person_in_child2)
  end
end
