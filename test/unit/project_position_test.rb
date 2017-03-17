require 'test_helper'

class ProjectPositionTest < ActiveSupport::TestCase
  fixtures :project_positions

  test 'pal role' do
    position = ProjectPosition.pal_position
    assert_equal project_positions(:pal), position
  end

  test 'person can have project roles' do
    person = Factory(:pal)
    assert_includes person.project_positions, ProjectPosition.pal_position
  end

  test 'project roles removed when person removed from project' do
    person = Factory(:pal)

    assert_difference('GroupMembershipsProjectPosition.count', -1) do
      person.group_memberships.destroy_all
    end

    assert_empty person.project_positions
  end
end
