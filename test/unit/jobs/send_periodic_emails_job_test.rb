require 'test_helper'

class SendPeriodicEmailsJobTest < ActiveSupport::TestCase
  def setup
    User.current_user = Factory(:user)
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
  end

  def teardown
    Seek::Config.email_enabled = @val
  end

  test 'gather_logs' do
    count = 2
    activity_loggable = Factory(:data_file)
    other_activity_loggable = Factory(:data_file)
    culprit = activity_loggable.contributor
    count.times do
      Factory(:activity_log, action: 'create', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'update', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'show', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'destroy', activity_loggable: activity_loggable, culprit: culprit)
      Factory(:activity_log, action: 'download', activity_loggable: activity_loggable, culprit: culprit)
      # session create
      Factory(:activity_log, action: 'create', controller_name: 'sessions', culprit: culprit)
    end
    # only create and update actions are filtered
    # creation of session is excluded
    # only the latest relevant log for each resource is returned
    assert_equal 1, PeriodicSubscriptionEmailJob.new('daily').gather_logs(Time.now.yesterday.utc).length
    assert_equal 1, PeriodicSubscriptionEmailJob.new('weekly').gather_logs(7.days.ago).length
    assert_equal 1, PeriodicSubscriptionEmailJob.new('monthly').gather_logs(1.month.ago).length

    Factory(:activity_log, action: 'create', activity_loggable: other_activity_loggable, culprit: other_activity_loggable.contributor, created_at: 2.days.ago)
    assert_equal 1, PeriodicSubscriptionEmailJob.new('daily').gather_logs(Time.now.yesterday.utc).length
    assert_equal 2, PeriodicSubscriptionEmailJob.new('weekly').gather_logs(7.days.ago).length
    assert_equal 2, PeriodicSubscriptionEmailJob.new('monthly').gather_logs(1.month.ago).length
  end

  test 'no follow on job after perform' do
    # checks that a new job is created when perform is comples despite the current one being locked

    person1 = Factory(:person)

    assert_no_enqueued_jobs(only: PeriodicSubscriptionEmailJob) do
      PeriodicSubscriptionEmailJob.perform_now('daily')
    end
  end

  test 'perform' do
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    person4 = Factory(:person)
    sop = Factory(:sop, policy: Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(person_id: person1.id, project_id: sop.projects.first.id, frequency: 'daily')
    project_subscription2 = ProjectSubscription.create(person_id: person2.id, project_id: sop.projects.first.id, frequency: 'weekly')
    project_subscription3 = ProjectSubscription.create(person_id: person3.id, project_id: sop.projects.first.id, frequency: 'monthly')
    project_subscription4 = ProjectSubscription.create(person_id: person4.id, project_id: sop.projects.first.id, frequency: 'monthly')
    ProjectSubscriptionJob.perform_now(project_subscription1)
    ProjectSubscriptionJob.perform_now(project_subscription2)
    ProjectSubscriptionJob.perform_now(project_subscription3)
    ProjectSubscriptionJob.perform_now(project_subscription4)
    sop.reload

    Factory :activity_log, activity_loggable: sop, culprit: Factory(:user), action: 'create'
    Factory :activity_log, activity_loggable: nil, culprit: Factory(:user), action: 'search'

    assert_enqueued_emails 1 do
      PeriodicSubscriptionEmailJob.perform_now('daily')
    end
    assert_enqueued_emails 1 do
      PeriodicSubscriptionEmailJob.perform_now('weekly')
    end
    assert_enqueued_emails 2 do
      PeriodicSubscriptionEmailJob.perform_now('monthly')
    end
  end

  test 'perform ignores unwanted actions' do
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)
    sop = Factory(:sop, policy: Factory(:public_policy))
    project_subscription1 = ProjectSubscription.create(person_id: person1.id, project_id: sop.projects.first.id, frequency: 'daily')
    project_subscription2 = ProjectSubscription.create(person_id: person2.id, project_id: sop.projects.first.id, frequency: 'weekly')
    project_subscription3 = ProjectSubscription.create(person_id: person3.id, project_id: sop.projects.first.id, frequency: 'monthly')
    ProjectSubscriptionJob.perform_now(project_subscription1)
    ProjectSubscriptionJob.perform_now(project_subscription2)
    ProjectSubscriptionJob.perform_now(project_subscription3)
    sop.reload

    user = Factory :user

    assert_no_enqueued_emails do
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'show'
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'download'
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'destroy'

      PeriodicSubscriptionEmailJob.perform_now('daily')
      PeriodicSubscriptionEmailJob.perform_now('weekly')
      PeriodicSubscriptionEmailJob.perform_now('monthly')
    end
  end

  test 'perform2' do
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

    ps.each { |p| ProjectSubscriptionJob.perform_now(p) }

    user = Factory :user
    disable_authorization_checks do
      Factory :activity_log, activity_loggable: sop, culprit: user, action: 'update'
      Factory :activity_log, activity_loggable: model, culprit: user, action: 'update'
      Factory :activity_log, activity_loggable: data_file, culprit: user, action: 'update'
      Factory :activity_log, activity_loggable: data_file2, culprit: user, action: 'update'
    end

    assert_enqueued_emails 1 do
      PeriodicSubscriptionEmailJob.perform_now('daily')
    end
  end

  test 'select subscribers' do
    activity_loggable = Factory(:data_file, policy: Factory(:public_policy))
    p1 = activity_loggable.projects.first
    other_activity_loggable = Factory(:sop, policy: Factory(:public_policy))
    p2 = other_activity_loggable.projects.first
    shared_activity_loggable = Factory(:model, projects: [p1, p2], contributor: activity_loggable.contributor, policy: Factory(:public_policy))
    ActivityLog.delete_all

    Factory(:activity_log, action: 'update', activity_loggable: activity_loggable, culprit: activity_loggable.contributor, created_at: 1.hour.ago)
    Factory(:activity_log, action: 'update', activity_loggable: activity_loggable, culprit: activity_loggable.contributor, created_at: 3.days.ago)
    Factory(:activity_log, action: 'update', activity_loggable: other_activity_loggable, culprit: other_activity_loggable.contributor, created_at: 3.days.ago)
    Factory(:activity_log, action: 'update', activity_loggable: activity_loggable, culprit: activity_loggable.contributor, created_at: 3.weeks.ago)
    Factory(:activity_log, action: 'update', activity_loggable: other_activity_loggable, culprit: other_activity_loggable.contributor, created_at: 3.weeks.ago)
    Factory(:activity_log, action: 'update', activity_loggable: shared_activity_loggable, culprit: shared_activity_loggable.contributor, created_at: 3.weeks.ago)

    p1_daily_subscriber = Factory(:person)
    Factory(:project_subscription, person: p1_daily_subscriber, project_id: p1.id, frequency: 'daily').subscribe_to_all_in_project
    assert p1_daily_subscriber.receive_notifications?

    p1_monthly_subscriber = Factory(:person)
    Factory(:project_subscription, person: p1_monthly_subscriber, project_id: p1.id, frequency: 'monthly').subscribe_to_all_in_project
    assert p1_monthly_subscriber.receive_notifications?

    p2_daily_subscriber = Factory(:person)
    Factory(:project_subscription, person: p2_daily_subscriber, project_id: p2.id, frequency: 'daily').subscribe_to_all_in_project
    assert p2_daily_subscriber.receive_notifications?

    p2_monthly_subscriber_without_notification = Factory(:person)
    p2_monthly_subscriber_without_notification.notifiee_info.update_column(:receive_notifications, false)
    Factory(:project_subscription, person: p2_monthly_subscriber_without_notification, project_id: p2.id, frequency: 'monthly').subscribe_to_all_in_project
    refute p2_monthly_subscriber_without_notification.receive_notifications?

    # Daily
    freq = 'daily'
    job = PeriodicSubscriptionEmailJob.new(freq)
    logs = job.gather_logs(PeriodicSubscriptionEmailJob::DELAYS[freq].ago)
    assert_equal 1, logs.length
    group = job.group_by_subscriber(logs, freq)
    assert_equal 1, group.keys.length
    assert_includes group.keys, p1_daily_subscriber
    assert_equal 1, group[p1_daily_subscriber].length
    assert_includes group[p1_daily_subscriber].map(&:activity_loggable), activity_loggable

    # Weekly
    freq = 'weekly'
    job = PeriodicSubscriptionEmailJob.new(freq)
    logs = job.gather_logs(PeriodicSubscriptionEmailJob::DELAYS[freq].ago)
    assert_equal 2, logs.length
    group = job.group_by_subscriber(logs, freq)
    assert_equal 0, group.keys.length, 'There should be no weekly subscribers'

    # Monthly
    freq = 'monthly'
    job = PeriodicSubscriptionEmailJob.new(freq)
    logs = job.gather_logs(PeriodicSubscriptionEmailJob::DELAYS[freq].ago)
    assert_equal 3, logs.length
    group = job.group_by_subscriber(logs, freq)
    assert_equal 1, group.keys.length
    assert_includes group.keys, p1_monthly_subscriber
    assert_not_includes group.keys, p2_monthly_subscriber_without_notification, 'Subscriber with notifications disabled should not be notified'
    assert_equal 2, group[p1_monthly_subscriber].length
    loggables = group[p1_monthly_subscriber].map(&:activity_loggable)
    assert_includes loggables, activity_loggable
    assert_includes loggables, shared_activity_loggable

    # Should not show private things
    disable_authorization_checks do
      activity_loggable.policy.update_column(:access_type, Policy::PRIVATE)
      freq = 'daily'
      job = PeriodicSubscriptionEmailJob.new(freq)
      logs = job.gather_logs(PeriodicSubscriptionEmailJob::DELAYS[freq].ago)
      assert_equal 1, logs.length
      group = job.group_by_subscriber(logs, freq)
      assert_equal 0, group.keys.length
    end
  end
end
