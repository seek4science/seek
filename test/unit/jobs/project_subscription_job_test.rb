require 'test_helper'

class ProjectSubscriptionJobTest < ActiveSupport::TestCase
  test 'perform' do
    User.current_user = FactoryBot.create(:user)
    proj = FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj)
    person.add_to_project_and_institution(FactoryBot.create(:project), FactoryBot.create(:institution))
    s1 = FactoryBot.create(:subscribable, projects: person.projects, policy: FactoryBot.create(:public_policy), contributor:person)
    s2 = FactoryBot.create(:subscribable, projects: person.projects, policy: FactoryBot.create(:public_policy), contributor:person)

    a_person = FactoryBot.create(:person)
    assert !s1.subscribed?(a_person)
    assert !s2.subscribed?(a_person)

    ps = a_person.project_subscriptions.create project: proj, frequency: 'weekly'

    s1.reload
    s2.reload
    assert !s1.subscribed?(a_person)
    assert !s2.subscribed?(a_person)

    # perform
    ProjectSubscriptionJob.perform_now(ps)

    s1.reload
    s2.reload
    assert s1.subscribed?(a_person)
    assert s2.subscribed?(a_person)
  end
end
