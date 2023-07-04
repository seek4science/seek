
require 'test_helper'

class GroupMembershipTest < ActiveSupport::TestCase
  test 'person_can_be_removed?' do
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)
    project_administrator = FactoryBot.create(:project_administrator)
    programme_administrator = FactoryBot.create(:programme_administrator)
    project = FactoryBot.create(:project)

    # admin can remove themself and all other people
    gm = GroupMembership.new(person: admin, project: project)
    User.current_user = admin.user
    assert gm.person_can_be_removed?

    gm.person = person
    assert gm.person_can_be_removed?

    gm.person = project_administrator
    assert gm.person_can_be_removed?

    gm.person = programme_administrator
    assert gm.person_can_be_removed?

    # programme administrator can remove themself if in the same project they administer
    gm = GroupMembership.new(person: programme_administrator, project: programme_administrator.projects.first)
    User.current_user = programme_administrator.user
    assert gm.person_can_be_removed?

    gm.person = person
    assert gm.person_can_be_removed?

    gm.person = project_administrator
    assert gm.person_can_be_removed?

    gm.person = admin
    assert gm.person_can_be_removed?

    # programme administrator cannot remove themself if not in the same project they administer
    gm = GroupMembership.new(person: programme_administrator, project: FactoryBot.create(:project))
    User.current_user = programme_administrator.user
    refute gm.person_can_be_removed?

    gm.person = person
    assert gm.person_can_be_removed?

    gm.person = project_administrator
    assert gm.person_can_be_removed?

    gm.person = admin
    assert gm.person_can_be_removed?

    # project administrator cannot remove themself
    gm = GroupMembership.new(person: project_administrator, project: project_administrator.projects.first)
    User.current_user = project_administrator.user
    refute gm.person_can_be_removed?

    gm.person = person
    assert gm.person_can_be_removed?

    gm.person = programme_administrator
    assert gm.person_can_be_removed?

    gm.person = admin
    assert gm.person_can_be_removed?
  end
end
