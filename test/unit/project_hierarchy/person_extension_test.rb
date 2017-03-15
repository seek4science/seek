require 'test_helper'
require 'project_hierarchy_test_helper'

class PersonExtensionTest < ActiveSupport::TestCase
  include ProjectHierarchyTestHelper

  test "person's projects include direct projects and parent projects" do
    parent_proj = Factory :project
    proj = Factory :project, parent_id: parent_proj.id
    p = Factory(:brand_new_person, work_groups: [Factory(:work_group, project: proj)])
    assert_equal [parent_proj, proj].map(&:id).sort, p.projects.map(&:id).sort
  end

  test 'add also parent project subscriptions when adding new workgroups' do
    # when created without a project
    person = Factory(:brand_new_person)
    assert_equal 0, person.project_subscriptions.count

    # add 2 work_groups directly
    project1 = Factory :project, parent: @proj
    project2 = Factory :project, parent: @proj
    person.work_groups.create project: project1, institution: Factory(:institution)
    person.work_groups.create project: project2, institution: Factory(:institution)
    disable_authorization_checks do
      # save person in order to save built project subscriptions
      person.save!
    end
    assert_equal 3, person.project_subscriptions.count
  end

  test 'remove also child project subscriptions when removing workgroups' do
    # when created without a project
    person = Factory(:brand_new_person)
    assert_equal 0, person.project_subscriptions.count
    # subsribe to @proj after workgroups is added
    person.work_groups.create project: @proj, institution: Factory(:institution)

    # subscribe to @proj_child1
    person.project_subscriptions.create project_id: @proj_child1.id
    disable_authorization_checks do
      # save person in order to save built project subscriptions
      person.save!
    end
    assert_equal 2, person.project_subscriptions.count

    person.work_groups.delete WorkGroup.where(project_id: @proj).first
    assert_equal 0, person.project_subscriptions.count
  end
end
