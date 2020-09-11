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
    assert_equal 2 * count, PeriodicSubscriptionEmailJob.new('daily').activity_logs_since(Time.now.yesterday.utc).count
    assert_equal 2 * count, PeriodicSubscriptionEmailJob.new('weekly').activity_logs_since(7.days.ago).count
    assert_equal 2 * count, PeriodicSubscriptionEmailJob.new('monthly').activity_logs_since(1.month.ago).count

    Factory(:activity_log, action: 'create', activity_loggable: activity_loggable, culprit: culprit, created_at: 2.days.ago)
    assert_equal 2 * count, PeriodicSubscriptionEmailJob.new('daily').activity_logs_since(Time.now.yesterday.utc).count
    assert_equal 2 * count + 1, PeriodicSubscriptionEmailJob.new('weekly').activity_logs_since(7.days.ago).count
    assert_equal 2 * count + 1, PeriodicSubscriptionEmailJob.new('monthly').activity_logs_since(1.month.ago).count
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
end
