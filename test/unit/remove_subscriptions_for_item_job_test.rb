require 'test_helper'

class RemoveSubscriptionsForItemJobTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    User.current_user = Factory(:user)
  end

  test "exists" do
    subscribable = Factory(:subscribable)
    project_ids = subscribable.projects.collect(&:id)
    Delayed::Job.destroy_all
    assert !RemoveSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids)
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue RemoveSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, project_ids)
    end

    assert RemoveSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids)

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !RemoveSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids),"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !RemoveSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, project_ids),"Should ignore failed jobs"
  end

  test "create job" do
      subscribable = Factory(:subscribable)
      project_ids = subscribable.projects.collect(&:id)

      Delayed::Job.destroy_all
      assert_equal 0,Delayed::Job.count
      RemoveSubscriptionsForItemJob.create_job(subscribable.class.name, subscribable.id, project_ids)
      assert_equal 1,Delayed::Job.count

      job = Delayed::Job.first
      assert_equal 1,job.priority

      RemoveSubscriptionsForItemJob.create_job(subscribable.class.name, subscribable.id, project_ids)
      assert_equal 1,Delayed::Job.count
  end


  test "perform" do
    #set subscriptions
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    subscribable = Factory(:data_file, :policy => Factory(:public_policy))
    assert_equal 1, subscribable.projects.count
    project = subscribable.projects.first
    project_subscription1 = person1.project_subscriptions.create :project => project, :frequency => 'weekly'
    project_subscription2 = person2.project_subscriptions.create :project => project, :frequency => 'weekly'

    SetSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, subscribable.projects.collect(&:id)).perform

    assert subscribable.subscribed? person1
    assert subscribable.subscribed? person2

    #when subscribable changes the projects, RemoveSubscriptionsForItemJob is also created
    subscribable.projects = [Factory(:project)]
    subscribable.save
    assert RemoveSubscriptionsForItemJob.exists?(subscribable.class.name, subscribable.id, [project.id])

    #now remove subscriptions
    RemoveSubscriptionsForItemJob.new(subscribable.class.name, subscribable.id, [project.id]).perform
    subscribable.reload
    assert !subscribable.subscribed?(person1)
    assert !subscribable.subscribed?(person2)
  end
end