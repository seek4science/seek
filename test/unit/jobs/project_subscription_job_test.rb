require 'test_helper'

class ProjectSubscriptionJobTest < ActiveSupport::TestCase
  test 'all_in_project' do
    person = Factory(:person)
    project = person.projects.first
    ps = Factory(:project_subscription, project: project)
    assets = ProjectSubscriptionJob.new(1).send(:all_in_project, project)
    assert assets.empty?

    # create items for project
    ps.subscribable_types.collect(&:name).reject { |t| t == 'Assay' || t == 'Study' }.each do |type|
      Factory(type.underscore.tr('/', '_').to_s, projects: [project], contributor: person)
    end
    project.reload
    # study
    study = Factory(:study, investigation: project.investigations.first, contributor: person)
    # assay
    Factory(:assay, study: study, contributor: person)

    assets = ProjectSubscriptionJob.new(1).all_in_project project
    # cause without openbis
    assert_equal ps.subscribable_types.count, assets.count
  end

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
