require 'test_helper'

class SendPeriodicEmailsJobTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled=true
    Delayed::Job.destroy_all
  end

  def teardown
    Delayed::Job.destroy_all
    Seek::Config.email_enabled=@val
  end

  test "exists" do
    assert !SendPeriodicEmailsJob.daily_exists?
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue SendPeriodicEmailsJob.new('daily')
    end

    assert SendPeriodicEmailsJob.daily_exists?

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !SendPeriodicEmailsJob.daily_exists?,"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !SendPeriodicEmailsJob.daily_exists?,"Should ignore failed jobs"
  end

  test "create job" do
      assert_equal 0,Delayed::Job.count
      SendPeriodicEmailsJob.create_job('daily', Time.now)
      assert_equal 1,Delayed::Job.count

      job = Delayed::Job.first
      assert_equal 1,job.priority

      SendPeriodicEmailsJob.create_job('daily', Time.now)
      assert_equal 1,Delayed::Job.count
  end


  test "perform" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    sop = Factory(:sop, :policy => Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(:person_id => person1.id, :project_id => sop.projects.first.id, :frequency => 'daily')
    project_subscription2 = ProjectSubscription.create(:person_id => person2.id, :project_id => sop.projects.first.id, :frequency => 'weekly')
    project_subscription3 = ProjectSubscription.create(:person_id => person3.id, :project_id => sop.projects.first.id, :frequency => 'monthly')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform
    ProjectSubscriptionJob.new(project_subscription3.id).perform
    sop.reload

    SendPeriodicEmailsJob.create_job('daily', 15.minutes.from_now)
    SendPeriodicEmailsJob.create_job('weekly', 15.minutes.from_now)
    SendPeriodicEmailsJob.create_job('monthly', 15.minutes.from_now)
    assert_emails 3 do
      disable_authorization_checks do
        ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'create')
      end
      SendPeriodicEmailsJob.new('daily').perform
      SendPeriodicEmailsJob.new('weekly').perform
      SendPeriodicEmailsJob.new('monthly').perform
    end
  end

  test "perform ignores unwanted actions" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    sop = Factory(:sop, :policy => Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(:person_id => person1.id, :project_id => sop.projects.first.id, :frequency => 'daily')
    project_subscription2 = ProjectSubscription.create(:person_id => person2.id, :project_id => sop.projects.first.id, :frequency => 'weekly')
    project_subscription3 = ProjectSubscription.create(:person_id => person3.id, :project_id => sop.projects.first.id, :frequency => 'monthly')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform
    ProjectSubscriptionJob.new(project_subscription3.id).perform
    sop.reload

    SendPeriodicEmailsJob.create_job('daily', 15.minutes.from_now)
    SendPeriodicEmailsJob.create_job('weekly', 15.minutes.from_now)
    SendPeriodicEmailsJob.create_job('monthly', 15.minutes.from_now)
    assert_emails 0 do
      disable_authorization_checks do
        ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'show')
        ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'download')
        ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'destroy')
      end
      SendPeriodicEmailsJob.new('daily').perform
      SendPeriodicEmailsJob.new('weekly').perform
      SendPeriodicEmailsJob.new('monthly').perform
    end
  end
end