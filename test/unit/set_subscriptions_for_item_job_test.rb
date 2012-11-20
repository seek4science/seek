require 'test_helper'

class SetSubscriptionsForItemJobTest < ActiveSupport::TestCase
  fixtures :all

  test "exists" do
    subscribable = Factory(:subscribable)
    project_ids = subscribable.projects.collect(&:id)
    Delayed::Job.destroy_all
    assert !SetSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids)
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue SetSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, project_ids)
    end

    assert SetSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids)

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert_not_nil job.locked_at
    assert !SetSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids),"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !SetSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids),"Should ignore failed jobs"
  end

  test "create job" do
      subscribable = Factory(:subscribable)
      project_ids = subscribable.projects.collect(&:id)
      Delayed::Job.destroy_all
      assert_equal 0,Delayed::Job.count
      SetSubscriptionsForItemJob.create_job(subscribable.class.name, subscribable.id, project_ids)
      assert_equal 1,Delayed::Job.count

      job = Delayed::Job.first
      assert_equal 1,job.priority

      SetSubscriptionsForItemJob.create_job(subscribable.class.name, subscribable.id, project_ids)
      assert_equal 1,Delayed::Job.count
  end


  test "perform for datafile" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = Factory(:data_file)
    project_subscription1 = ProjectSubscription.create(:person_id => person1.id, :project_id => subscribable.projects.first.id, :frequency => 'immediately')
    project_subscription2 = ProjectSubscription.create(:person_id => person2.id, :project_id => subscribable.projects.first.id, :frequency => 'immediately')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform

    SetSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, subscribable.projects.collect(&:id)).perform

    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2
  end

  test "perform for assay" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = Factory(:assay, :policy => Factory(:public_policy))
    assert_equal 1, subscribable.projects.count
    project_subscription1 = ProjectSubscription.create(:person_id => person1.id, :project_id => subscribable.projects.first.id, :frequency => 'immediately')
    project_subscription2 = ProjectSubscription.create(:person_id => person2.id, :project_id => subscribable.projects.first.id, :frequency => 'immediately')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform

    puts person1.projects.inspect
    puts person2.projects.inspect

    puts subscribable.projects.inspect

    assert_equal person1.project_subscriptions.collect(&:project),subscribable.projects

    SetSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, subscribable.projects.collect(&:id)).perform

    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2
  end

  test "perform for study" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = Factory(:study)
    project_subscription1 = ProjectSubscription.create(:person_id => person1.id, :project_id => subscribable.projects.first.id, :frequency => 'immediately')
    project_subscription2 = ProjectSubscription.create(:person_id => person2.id, :project_id => subscribable.projects.first.id, :frequency => 'immediately')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform
    SetSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, subscribable.projects.collect(&:id)).perform

    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2
  end
end