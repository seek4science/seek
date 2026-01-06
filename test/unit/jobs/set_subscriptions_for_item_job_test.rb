require 'test_helper'

class SetSubscriptionsForItemJobTest < ActiveSupport::TestCase

  def setup
    User.current_user = FactoryBot.create(:user)
  end

  test 'perform for datafile' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    subscribable = nil
    # when subscribable is created, SetSubscriptionsForItemJob is also created
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      subscribable = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
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
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    subscribable = nil
    # when subscribable is created, SetSubscriptionsForItemJob is also created
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      subscribable = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
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
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    subscribable = nil
    # when subscribable is created, SetSubscriptionsForItemJob is also created
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      subscribable = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
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
