require 'test_helper'

class SetSubscriptionsForItemJobTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    User.current_user = Factory(:user)
  end

  test 'perform for datafile' do
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = nil
    # when subscribable is created, SetSubscriptionsForItemJob is also created
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      subscribable = Factory(:data_file, policy: Factory(:public_policy))
    end
    assert_equal 1, subscribable.projects.count
    project_subscription1 = person1.project_subscriptions.create project: subscribable.projects.first, frequency: 'weekly'
    project_subscription2 = person2.project_subscriptions.create project: subscribable.projects.first, frequency: 'weekly'

    assert !subscribable.subscribed?(person1)
    assert !subscribable.subscribed?(person2)

    SetSubscriptionsForItemJob.perform_now(subscribable, subscribable.projects)

    subscribable.reload
    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2
  end

  test 'perform for assay' do
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = nil
    # when subscribable is created, SetSubscriptionsForItemJob is also created
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      subscribable = Factory(:assay, policy: Factory(:public_policy))
    end
    assert_equal 1, subscribable.projects.count
    project_subscription1 = person1.project_subscriptions.create project: subscribable.projects.first, frequency: 'weekly'
    project_subscription2 = person2.project_subscriptions.create project: subscribable.projects.first, frequency: 'weekly'

    assert !subscribable.subscribed?(person1)
    assert !subscribable.subscribed?(person2)

    SetSubscriptionsForItemJob.perform_now(subscribable, subscribable.projects)

    subscribable.reload
    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2
  end

  test 'perform for study' do
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = nil
    # when subscribable is created, SetSubscriptionsForItemJob is also created
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      subscribable = Factory(:study, policy: Factory(:public_policy))
    end
    assert_equal 1, subscribable.projects.count
    project_subscription1 = person1.project_subscriptions.create project: subscribable.projects.first, frequency: 'weekly'
    project_subscription2 = person2.project_subscriptions.create project: subscribable.projects.first, frequency: 'weekly'

    assert !subscribable.subscribed?(person1)
    assert !subscribable.subscribed?(person2)

    SetSubscriptionsForItemJob.perform_now(subscribable, subscribable.projects)

    subscribable.reload
    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2
  end
end
