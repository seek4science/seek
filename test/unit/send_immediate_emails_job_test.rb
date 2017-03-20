require 'test_helper'

class SendImmediateEmailsJobTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
    Seek::Config.email_enabled = @val
  end

  test 'exists' do
    activity_log_id = 1
    assert !SendImmediateEmailsJob.new(activity_log_id).exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue SendImmediateEmailsJob.new(activity_log_id)
    end

    assert SendImmediateEmailsJob.new(activity_log_id).exists?

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !SendImmediateEmailsJob.new(activity_log_id).exists?, 'Should ignore locked jobs'

    job.locked_at = nil
    job.failed_at = Time.now
    job.save!
    assert !SendImmediateEmailsJob.new(activity_log_id).exists?, 'Should ignore failed jobs'
  end

  test 'create job' do
    assert_difference('Delayed::Job.count', 1) do
      SendImmediateEmailsJob.new(1).queue_job
    end

    job = Delayed::Job.first
    assert_equal 3, job.priority

    assert_no_difference('Delayed::Job.count') do
      SendImmediateEmailsJob.new(1).queue_job
    end
  end

  test 'perform' do
    Delayed::Job.delete_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    sop = Factory(:sop, policy: Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(person_id: person1.id, project_id: sop.projects.first.id, frequency: 'immediately')
    project_subscription2 = ProjectSubscription.create(person_id: person2.id, project_id: sop.projects.first.id, frequency: 'immediately')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform
    assert_emails 2 do
      disable_authorization_checks do
        al = ActivityLog.create(activity_loggable: sop, culprit: Factory(:user), action: 'create')
        SendImmediateEmailsJob.new(al.id).perform
      end
    end
  end
end
