require 'test_helper'

class ProjectRoleTest < ActiveSupport::TestCase
  fixtures :project_roles

  test "pal role" do
    role = ProjectRole.pal_role
    assert_equal project_roles(:pal),role
  end

  test "person can have project roles" do
    person = Factory(:pal)
    assert_includes person.project_roles, ProjectRole.pal_role
  end

  test "project roles removed when person removed from project" do
    person = Factory(:pal)

    assert_difference('GroupMembershipsProjectRole.count', -1) do
      person.group_memberships.destroy_all
    end

    assert_empty person.project_roles
  end

end