require 'test_helper'

class ProjectSubscriptionJobTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    Delayed::Job.destroy_all
  end

  def teardown
    Delayed::Job.destroy_all
  end

  test "exists" do
    project_subscription_id = 1
    assert !ProjectSubscriptionJob.exists?(project_subscription_id)
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue ProjectSubscriptionJob.new(project_subscription_id)
    end

    assert ProjectSubscriptionJob.exists?(project_subscription_id)

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !ProjectSubscriptionJob.exists?(project_subscription_id),"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !ProjectSubscriptionJob.exists?(project_subscription_id),"Should ignore failed jobs"
  end

  test "create job" do
      assert_difference("Delayed::Job.count",1) do
        ProjectSubscriptionJob.create_job(1)
      end

      job = Delayed::Job.first
      assert_equal 2,job.priority

      assert_no_difference("Delayed::Job.count") do
        ProjectSubscriptionJob.create_job(1)
      end
  end

  test "all_in_project" do
    project = Factory(:project)
    ps = Factory(:project_subscription, :project => project)
    assets = ProjectSubscriptionJob.new.all_in_project ps
    assert assets.empty?

    #create items for project
    ps.subscribable_types.reject{|t| t=='Assay' || t=='Study'}.each do |type|
      Factory("#{type.underscore.gsub('/','_')}", :projects => [project])
    end
    project.reload
    #study
    study = Factory(:study, :investigation => project.investigations.first)
    #assay
    Factory(:assay, :study => study)

    assets = ProjectSubscriptionJob.new.all_in_project ps
    assert_equal ps.subscribable_types.count, assets.count
  end

  test "perform" do
    User.current_user = Factory(:user)
    proj = Factory(:project)
    s1 = Factory(:subscribable, :projects => [Factory(:project), proj], :policy => Factory(:public_policy))
    s2 = Factory(:subscribable, :projects => [Factory(:project), proj], :policy => Factory(:public_policy))

    a_person = Factory(:person)
    assert !s1.subscribed?(a_person)
    assert !s2.subscribed?(a_person)

    ps = a_person.project_subscriptions.create :project => proj, :frequency => 'weekly'

    s1.reload
    s2.reload
    assert !s1.subscribed?(a_person)
    assert !s2.subscribed?(a_person)

    #perform
    ProjectSubscriptionJob.new(ps.id).perform

    s1.reload
    s2.reload
    assert s1.subscribed?(a_person)
    assert s2.subscribed?(a_person)

  end
end