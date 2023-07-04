require 'test_helper'

class RemoveSubscriptionsForItemJobTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    User.current_user = FactoryBot.create(:user)
  end

  test 'perform' do
    # set subscriptions
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    subscribable = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
    assert_equal 1, subscribable.projects.count
    project = subscribable.projects.first
    project_subscription1 = person1.project_subscriptions.create project: project, frequency: 'weekly'
    project_subscription2 = person2.project_subscriptions.create project: project, frequency: 'weekly'

    SetSubscriptionsForItemJob.perform_now(subscribable, subscribable.projects)

    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2

    # when subscribable changes the projects, RemoveSubscriptionsForItemJob is also created

    proj = FactoryBot.create(:project)
    assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [subscribable, [project]]) do
      subscribable.projects = [proj]
      subscribable.save
    end

    # now remove subscriptions
    RemoveSubscriptionsForItemJob.perform_now(subscribable, [project])
    subscribable.reload
    assert !subscribable.subscribed?(person1)
    assert !subscribable.subscribed?(person2)
  end
end
