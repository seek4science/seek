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

  test "perform" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    sop = Factory(:sop, :policy => Factory(:public_policy))
    ProjectSubscription.create(:person_id => person1.id, :project_id => sop.projects.first.id, :frequency => 'daily')
    ProjectSubscription.create(:person_id => person2.id, :project_id => sop.projects.first.id, :frequency => 'weekly')
    ProjectSubscription.create(:person_id => person3.id, :project_id => sop.projects.first.id, :frequency => 'monthly')

    assert_emails 1 do
      disable_authorization_checks do
        ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'create')
      end
      SendPeriodicEmailsJob.new('daily').perform
      SendPeriodicEmailsJob.new('weekly').perform
      SendPeriodicEmailsJob.new('monthly').perform
    end

    assert_equal 4, Delayed::Job.count #one job for sending immediately
  end
end