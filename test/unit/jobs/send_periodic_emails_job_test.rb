require 'test_helper'

class SendPeriodicEmailsJobTest < ActiveSupport::TestCase
  def setup
    User.current_user = Factory(:user)
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
    Seek::Config.email_enabled = @val
  end

  test 'exists' do
    assert !SendPeriodicEmailsJob.daily_exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue SendPeriodicEmailsJob.new('daily')
    end

    assert SendPeriodicEmailsJob.daily_exists?
    assert SendPeriodicEmailsJob.new('daily').exists?
    assert SendPeriodicEmailsJob.new('daily').exists?(true)

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert SendPeriodicEmailsJob.daily_exists?, 'Should not ignore locked jobs'
    assert SendPeriodicEmailsJob.new('daily').exists?
    assert !SendPeriodicEmailsJob.new('daily').exists?(true)

    job.locked_at = nil
    job.failed_at = Time.now
    job.save!
    assert !SendPeriodicEmailsJob.daily_exists?, 'Should ignore failed jobs'
    assert !SendPeriodicEmailsJob.new('daily').exists?
    assert !SendPeriodicEmailsJob.new('daily').exists?(true)

    job.failed_at = nil
    job.save!
    assert SendPeriodicEmailsJob.daily_exists?
    assert SendPeriodicEmailsJob.new('daily').exists?

    assert !SendPeriodicEmailsJob.weekly_exists?
    assert_difference('Delayed::Job.count', 1) do
      job = Delayed::Job.enqueue SendPeriodicEmailsJob.new('weekly')
    end
    assert SendPeriodicEmailsJob.weekly_exists?
    assert SendPeriodicEmailsJob.new('weekly').exists?
    assert SendPeriodicEmailsJob.new('weekly').exists?(true)
    job.locked_at = Time.now
    job.save!
    assert SendPeriodicEmailsJob.weekly_exists?
    assert SendPeriodicEmailsJob.new('weekly').exists?
    assert !SendPeriodicEmailsJob.new('weekly').exists?(true)

    assert !SendPeriodicEmailsJob.monthly_exists?
    assert_difference('Delayed::Job.count', 1) do
      job = Delayed::Job.enqueue SendPeriodicEmailsJob.new('monthly')
    end
    assert SendPeriodicEmailsJob.monthly_exists?
    assert SendPeriodicEmailsJob.new('monthly').exists?
    assert SendPeriodicEmailsJob.new('monthly').exists?(true)
    job.locked_at = Time.now
    job.save!
    assert SendPeriodicEmailsJob.weekly_exists?
    assert SendPeriodicEmailsJob.new('monthly').exists?
    assert !SendPeriodicEmailsJob.new('monthly').exists?(true)
  end

  test 'activity_logs_since' do
    count = 2
    i = 0
    activity_loggable = Factory(:data_file)
    culprit = activity_loggable.contributor
    while i < count
      Factory(:activity_log, action: 'create', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'update', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'show', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'destroy', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'download', activity_loggable: activity_loggable, culprit: culprit)
      # session create
      Factory(:activity_log, action: 'create', controller_name: 'sessions', culprit: culprit)

      i += 1
    end
    # only create and update actions are filtered
    # creation of session is excluded
    assert_equal 2 * count, SendPeriodicEmailsJob.new('daily').activity_logs_since(Time.now.yesterday.utc).count
    assert_equal 2 * count, SendPeriodicEmailsJob.new('weekly').activity_logs_since(7.days.ago).count
    assert_equal 2 * count, SendPeriodicEmailsJob.new('monthly').activity_logs_since(1.month.ago).count

    Factory(:activity_log, action: 'create', activity_loggable: activity_loggable, culprit: culprit, created_at: 2.days.ago)
    assert_equal 2 * count, SendPeriodicEmailsJob.new('daily').activity_logs_since(Time.now.yesterday.utc).count
    assert_equal 2 * count + 1, SendPeriodicEmailsJob.new('weekly').activity_logs_since(7.days.ago).count
    assert_equal 2 * count + 1, SendPeriodicEmailsJob.new('monthly').activity_logs_since(1.month.ago).count
  end

  test 'create job' do
    assert_equal 0, Delayed::Job.count
    assert_difference('Delayed::Job.count', 1) do
      SendPeriodicEmailsJob.new('daily').queue_job
    end

    assert_equal 1, Delayed::Job.count

    job = Delayed::Job.first
    assert_equal 3, job.priority

    assert_no_difference('Delayed::Job.count') do
      SendPeriodicEmailsJob.new('daily').queue_job
    end

    assert_equal 1, Delayed::Job.count

    assert_difference('Delayed::Job.count', 1) do
      job = SendPeriodicEmailsJob.new('weekly').queue_job
    end
    assert_no_difference('Delayed::Job.count') do
      SendPeriodicEmailsJob.new('weekly').queue_job
    end
    job.locked_at = Time.now
    job.save!
    assert_no_difference('Delayed::Job.count') do
      SendPeriodicEmailsJob.new('weekly').queue_job
    end
  end

  test 'creation of follow on job after perform' do
    # checks that a new job is created when perform is comples despite the current one being locked

    person1 = Factory(:person)
    job = nil
    assert_difference('Delayed::Job.count', 1) do
      job = SendPeriodicEmailsJob.new('daily').queue_job(1, 15.minutes.from_now)
    end
    job.locked_at = Time.now
    job.save!
    assert_difference('Delayed::Job.count', 1) do
      SendPeriodicEmailsJob.new('daily').perform
    end
  end

  test 'perform' do
    Delayed::Job.delete_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    person4 = Factory(:person)
    sop = Factory(:sop, policy: Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(person_id: person1.id, project_id: sop.projects.first.id, frequency: 'daily')
    project_subscription2 = ProjectSubscription.create(person_id: person2.id, project_id: sop.projects.first.id, frequency: 'weekly')
    project_subscription3 = ProjectSubscription.create(person_id: person3.id, project_id: sop.projects.first.id, frequency: 'monthly')
    project_subscription4 = ProjectSubscription.create(person_id: person4.id, project_id: sop.projects.first.id, frequency: 'monthly')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform
    ProjectSubscriptionJob.new(project_subscription3.id).perform
    ProjectSubscriptionJob.new(project_subscription4.id).perform
    sop.reload

    SendPeriodicEmailsJob.new('daily').queue_job(1, 15.minutes.from_now)
    SendPeriodicEmailsJob.new('weekly').queue_job(1, 15.minutes.from_now)
    SendPeriodicEmailsJob.new('monthly').queue_job(1, 15.minutes.from_now)

    Factory :activity_log, activity_loggable: sop, culprit: Factory(:user), action: 'create'
    Factory :activity_log, activity_loggable: nil, culprit: Factory(:user), action: 'search'

    assert_emails 1 do
      SendPeriodicEmailsJob.new('daily').perform
    end
    assert_emails 1 do
      SendPeriodicEmailsJob.new('weekly').perform
    end
    assert_emails 2 do
      SendPeriodicEmailsJob.new('monthly').perform
    end
  end

  test 'perform ignores unwanted actions' do
    Delayed::Job.delete_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    sop = Factory(:sop, policy: Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(person_id: person1.id, project_id: sop.projects.first.id, frequency: 'daily')
    project_subscription2 = ProjectSubscription.create(person_id: person2.id, project_id: sop.projects.first.id, frequency: 'weekly')
    project_subscription3 = ProjectSubscription.create(person_id: person3.id, project_id: sop.projects.first.id, frequency: 'monthly')
    ProjectSubscriptionJob.new(project_subscription1.id).perform
    ProjectSubscriptionJob.new(project_subscription2.id).perform
    ProjectSubscriptionJob.new(project_subscription3.id).perform
    sop.reload

    SendPeriodicEmailsJob.new('daily').queue_job(1, 15.minutes.from_now)
    SendPeriodicEmailsJob.new('weekly').queue_job(1, 15.minutes.from_now)
    SendPeriodicEmailsJob.new('monthly').queue_job(1, 15.minutes.from_now)

    user = Factory :user

    assert_emails 0 do
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'show'
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'download'
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'destroy'

      SendPeriodicEmailsJob.new('daily').perform
      SendPeriodicEmailsJob.new('weekly').perform
      SendPeriodicEmailsJob.new('monthly').perform
    end
  end

  test 'perform2' do
    Delayed::Job.delete_all

    person1 = Factory :person
    person2 = Factory :person
    person3 = Factory :person, group_memberships: [Factory(:group_membership, work_group: person2.work_groups[0])]
    person4 = Factory :person, group_memberships: [Factory(:group_membership, work_group: person2.work_groups[0])]
    person4.notifiee_info.receive_notifications = false
    person4.notifiee_info.save!
    project1 = person1.projects.first
    project2 = person2.projects.first
    project3 = person3.projects.first
    assert_not_equal project1, project2
    assert_equal project2, project3

    sop = Factory(:sop, policy: Factory(:private_policy), contributor: person1, projects: [project1])
    model = Factory(:model, policy: Factory(:private_policy), contributor: person2, projects: [project2])
    data_file = Factory(:data_file, policy: Factory(:private_policy), contributor: person3, projects: [project2])
    data_file2 = Factory(:data_file, policy: Factory(:public_policy), contributor: person3, projects: [project2])

    ProjectSubscription.destroy_all
    Subscription.destroy_all

    ps = []
    ps << ProjectSubscription.create(person_id: person1.id, project_id: project1.id, frequency: 'daily')
    ps << Factory(:project_subscription, person_id: person1.id, project_id: project2.id, frequency: 'daily')
    ps << Factory(:project_subscription, person_id: person2.id, project_id: project1.id, frequency: 'daily')
    ps << Factory(:project_subscription, person_id: person3.id, project_id: project1.id, frequency: 'daily')
    ps << Factory(:project_subscription, person_id: person4.id, project_id: project1.id, frequency: 'daily')
    ps << ProjectSubscription.create(person_id: person4.id, project_id: project2.id, frequency: 'daily')

    ps.each { |p| ProjectSubscriptionJob.new(p.id).perform }

    user = Factory :user
    disable_authorization_checks do
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'update'
      Factory :activity_log, activity_loggable: model, culprit: user, action: 'update'
      Factory :activity_log, activity_loggable: data_file, culprit: user, action: 'update'
      Factory :activity_log, activity_loggable: data_file2, culprit: user, action: 'update'
    end

    assert_emails 1 do
      SendPeriodicEmailsJob.new('daily').perform
    end
  end

  test 'create_initial_jobs should not create jobs when they exist' do
    assert !SendPeriodicEmailsJob.daily_exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue SendPeriodicEmailsJob.new('daily')
    end
    assert_equal 1, Delayed::Job.count
    SendPeriodicEmailsJob.create_initial_jobs
    assert_equal 3, Delayed::Job.count
  end
end
