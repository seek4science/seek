require 'test_helper'

class ProjectSubscriptionJobTest < ActiveSupport::TestCase
  test 'perform' do
    User.current_user = Factory(:user)
    proj = Factory(:project)
    person = Factory(:person,project:proj)
    person.add_to_project_and_institution(Factory(:project), Factory(:institution))
    s1 = Factory(:subscribable, projects: person.projects, policy: Factory(:public_policy), contributor:person)
    s2 = Factory(:subscribable, projects: person.projects, policy: Factory(:public_policy), contributor:person)

    a_person = Factory(:person)
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
