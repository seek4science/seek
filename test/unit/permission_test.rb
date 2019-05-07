require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  fixtures :all

  test 'cleans up project permissions after delete' do
    person = Factory(:person)
    p1 = person.projects.first
    p2 = Factory(:project)
    person.add_to_project_and_institution(p2, Factory(:institution))
    data_file = Factory(:data_file, projects: [p1], contributor: person)

    assert_difference('Permission.count', 1) do
      data_file.policy.permissions.create!(contributor: p2, access_type: Policy::MANAGING)
    end

    assert data_file.policy.reload.permissions.where(contributor_id: p2, contributor_type: 'Project').any?

    assert_difference('Permission.count', -1) do
      person.group_memberships.last.destroy!
      disable_authorization_checks { p2.destroy! }
    end

    refute data_file.policy.reload.permissions.where(contributor_id: p2, contributor_type: 'Project').any?
  end
end
