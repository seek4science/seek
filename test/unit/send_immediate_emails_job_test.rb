require 'test_helper'

class SendImmediateEmailsJobTest < ActiveSupport::TestCase
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
    activity_log_id = 1
    assert !SendImmediateEmailsJob.exists?(activity_log_id)
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue SendImmediateEmailsJob.new(activity_log_id)
    end

    assert SendImmediateEmailsJob.exists?(activity_log_id)

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !SendImmediateEmailsJob.exists?(activity_log_id),"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !SendImmediateEmailsJob.exists?(activity_log_id),"Should ignore failed jobs"
  end

  test "create job" do
      assert_equal 0,Delayed::Job.count
      SendImmediateEmailsJob.create_job(1)
      assert_equal 1,Delayed::Job.count

      job = Delayed::Job.first
      assert_equal 1,job.priority

      SendImmediateEmailsJob.create_job(1)
      assert_equal 1,Delayed::Job.count
  end


  test "perform" do
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    sop = Factory(:sop, :policy => Factory(:public_policy))
    ProjectSubscription.create(:person_id => person1.id, :project_id => sop.projects.first.id, :frequency => 'immediately')
    ProjectSubscription.create(:person_id => person2.id, :project_id => sop.projects.first.id, :frequency => 'immediately')
    assert_emails 2 do
      disable_authorization_checks do
        al = ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'create')
        SendImmediateEmailsJob.new(al.id).perform
      end
    end
  end
end