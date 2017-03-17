require 'test_helper'
# Authorization tests that are specific to public access
class SubscriptionTest < ActiveSupport::TestCase
  fixtures :all

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

  test 'for_susbscribable' do
    p = User.current_user.person
    p2 = Factory :person
    sop = Factory :sop
    sop2 = Factory :sop
    assay = Factory :sop
    assay2 = Factory :sop
    Factory :subscription, person: p, subscribable: sop
    Factory :subscription, person: p2, subscribable: sop
    Factory :subscription, person: p, subscribable: sop2
    Factory :subscription, person: p, subscribable: assay
    Factory :subscription, person: p, subscribable: assay2

    assert_equal 2, Subscription.for_subscribable(sop).count
    assert_equal [sop, sop], Subscription.for_subscribable(sop).collect(&:subscribable)
    assert_equal [assay], Subscription.for_subscribable(assay).collect(&:subscribable)
    assert_equal [sop], p.subscriptions.for_subscribable(sop).collect(&:subscribable)
  end

  test 'subscribing and unsubscribing toggle subscribed?' do
    s = Factory(:subscribable)

    assert !s.subscribed?
    s.subscribe
    s.reload
    assert s.subscribed?

    s.unsubscribe
    s.reload
    assert !s.subscribed?

    another_person = Factory(:person)
    assert !s.subscribed?(another_person)
    s.subscribe(another_person)
    s.reload
    assert s.subscribed?(another_person)
    s.unsubscribe(another_person)
    s.reload
    assert !s.subscribed?(another_person)
  end

  test 'can subscribe to someone elses subscribable' do
    s = Factory(:subscribable, contributor: Factory(:user))
    assert !s.subscribed?
    s.subscribe
    assert s.save
    assert s.subscribed?
  end

  test 'subscribers with a frequency of immediate are sent emails when activity is logged' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'immediately'
    s = Factory(:subscribable, projects: [Factory(:project), proj], policy: Factory(:public_policy))
    s.subscribe

    assert_emails(1) do
      al = Factory(:activity_log, activity_loggable: s, action: 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end

    other_guy = Factory(:person)
    other_guy.project_subscriptions.create project: proj, frequency: 'immediately'
    s.reload
    s.subscribe(other_guy)

    assert_emails(2) do
      al = Factory(:activity_log, activity_loggable: s, action: 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end
  end

  test 'subscribers without a frequency of immediate are not sent emails when activity is logged' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    s = Factory(:subscribable, projects: [proj], policy: Factory(:public_policy))
    s.subscribe

    assert_no_emails do
      Factory(:activity_log, activity_loggable: s, action: 'update')
    end
  end

  test 'subscribers are not sent emails for items they cannot view' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'immediately'
    s = Factory(:subscribable, policy: Factory(:private_policy), contributor: Factory(:user), projects: [proj])

    assert_no_emails do
      User.with_current_user(s.contributor) do
        al = Factory(:activity_log, activity_loggable: s, action: 'update')
        SendImmediateEmailsJob.new(al.id).perform
      end
    end
  end

  test 'subscribers who do not receive notifications dont receive emails' do
    current_person.reload
    current_person.notifiee_info.receive_notifications = false
    current_person.notifiee_info.save!
    current_person.reload

    assert !current_person.receive_notifications?

    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'immediately'
    s = Factory(:subscribable, projects: [proj], policy: Factory(:public_policy))
    s.subscribe

    assert_no_emails do
      al = Factory(:activity_log, activity_loggable: s, action: 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end
  end

  test 'subscribers who are not registered dont receive emails' do
    person = Factory(:person_in_project)
    proj = Factory(:project)
    s = Factory(:subscribable, projects: [proj], policy: Factory(:public_policy))

    disable_authorization_checks do
      person.project_subscriptions.create project: proj, frequency: 'immediately'
      s.subscribe
    end

    assert_no_emails do
      al = Factory(:activity_log, activity_loggable: s, action: 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end
  end

  test 'set_default_subscriptions when one item is created' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    s = Factory(:subscribable, projects: [Factory(:project), proj], policy: Factory(:public_policy))
    assert SetSubscriptionsForItemJob.new(s, s.projects).exists?
    SetSubscriptionsForItemJob.new(s, s.projects).perform

    assert s.subscribed?(current_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'set_default_subscriptions when a study is created' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    investigation = Factory(:investigation, projects: [proj])
    study = Factory(:study, investigation: investigation, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?

    SetSubscriptionsForItemJob.new(study, study.projects).perform
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert study.subscribed?(current_person)
    assert investigation.subscribed?(current_person)
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'update subscriptions when changing a study associated to an assay' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    investigation = Factory(:investigation, projects: [proj])
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(assay, assay.projects).exists?
    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?

    SetSubscriptionsForItemJob.new(assay, assay.projects).perform
    SetSubscriptionsForItemJob.new(study, study.projects).perform
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert assay.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert investigation.subscribed?(current_person)
    assert_equal proj, current_person.subscriptions.first.project_subscription.project

    # changing study
    assay.study = Factory(:study)
    disable_authorization_checks { assay.save }

    RemoveSubscriptionsForItemJob.new(assay, assay.projects).exists?
    RemoveSubscriptionsForItemJob.new(assay, [proj]).perform

    assay.reload
    assert !assay.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert investigation.subscribed?(current_person)
  end

  test 'subscribe to all the items in a project when subscribing to that project' do
    proj = Factory(:project)
    s1 = Factory(:subscribable, projects: [Factory(:project), proj], policy: Factory(:public_policy))
    s2 = Factory(:subscribable, projects: [Factory(:project), proj], policy: Factory(:public_policy))

    assert !s1.subscribed?(current_person)
    assert !s2.subscribed?(current_person)

    project_subscription = current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    ProjectSubscriptionJob.new(project_subscription.id).perform
    s1.reload
    s2.reload
    assert s1.subscribed?(current_person)
    assert s2.subscribed?(current_person)
    assert_equal 2, current_person.subscriptions.count
    current_person.subscriptions.each do |s|
      assert_equal proj, s.project_subscription.project
    end
  end

  test 'should update subscription when changing the project associated with the item and a person did not subscribe to this project' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    projects = [Factory(:project), proj]
    s = Factory(:subscribable, projects: projects, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(s, s.projects).exists?
    SetSubscriptionsForItemJob.new(s, s.projects).perform

    assert s.subscribed?(current_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project

    # changing projects associated with the item
    updated_project = Factory(:project)

    disable_authorization_checks do
      s.projects = [updated_project]
      s.save
    end
    s.reload

    assert RemoveSubscriptionsForItemJob.new(s, [projects.first]).exists?
    assert RemoveSubscriptionsForItemJob.new(s, [projects[1]]).exists?
    RemoveSubscriptionsForItemJob.new(s, [projects.first]).perform
    RemoveSubscriptionsForItemJob.new(s, [projects[1]]).perform

    assert SetSubscriptionsForItemJob.new(s, [updated_project]).exists?
    SetSubscriptionsForItemJob.new(s, [updated_project]).perform

    assert_equal 1, s.projects.count
    assert_equal updated_project, s.projects.first

    # should no longer subscribe to this item because of changing project
    assert !s.subscribed?(current_person)
  end

  test 'should update subscription when associating the project to the item and a person subscribed to this project' do
    s = Factory(:subscribable, policy: Factory(:public_policy))
    project = s.projects.first

    assert SetSubscriptionsForItemJob.new(s, s.projects).exists?
    SetSubscriptionsForItemJob.new(s, s.projects).perform

    assert !s.subscribed?(current_person)

    # changing projects associated with the item
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'

    disable_authorization_checks do
      s.projects << proj
      s.save
    end

    assert SetSubscriptionsForItemJob.new(s, [proj]).exists?
    SetSubscriptionsForItemJob.new(s, [proj]).perform

    s.reload
    assert s.subscribed?(current_person)
  end

  test 'should update subscription when associating multiple projects to the item and a person subscribed to this project' do
    s = data_files(:picture)
    assert_equal 1, s.projects.count
    project = s.projects.first

    assert !s.subscribed?(current_person)

    # changing projects associated with the item
    proj1 = Factory(:project)
    proj2 = Factory(:project)
    current_person.project_subscriptions.create project: proj1, frequency: 'weekly'
    current_person.project_subscriptions.create project: proj2, frequency: 'weekly'

    disable_authorization_checks do
      s.projects = [proj1, proj2]
      s.save
    end

    assert SetSubscriptionsForItemJob.new(s, [proj1]).exists?
    assert SetSubscriptionsForItemJob.new(s, [proj2]).exists?
    assert RemoveSubscriptionsForItemJob.new(s, [project]).exists?
    SetSubscriptionsForItemJob.new(s, [proj1]).perform
    SetSubscriptionsForItemJob.new(s, [proj2]).perform

    s.reload
    assert s.subscribed?(current_person)
  end

  test 'should remove subscriptions when updating the projects associating to an investigation' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?
    investigation = Factory(:investigation, projects: [proj])
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(assay, assay.projects).exists?
    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?
    SetSubscriptionsForItemJob.new(assay, assay.projects).perform
    SetSubscriptionsForItemJob.new(study, study.projects).perform
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)

    # changing projects associated with the investigation
    updated_project = Factory(:project)
    investigation.reload
    disable_authorization_checks do
      investigation.projects = [updated_project]
      investigation.save
    end

    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert RemoveSubscriptionsForItemJob.new(investigation, [proj]).exists?
    RemoveSubscriptionsForItemJob.new(investigation, [proj]).perform

    investigation.reload
    study.reload
    assay.reload
    assert !investigation.subscribed?(current_person)
    assert !study.subscribed?(current_person)
    assert !assay.subscribed?(current_person)
  end

  test 'should add subscriptions when updating the projects associating to an investigation' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?
    investigation = Factory(:investigation, projects: [Factory(:project)])
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(assay, assay.projects).exists?
    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?
    SetSubscriptionsForItemJob.new(assay, assay.projects).perform
    SetSubscriptionsForItemJob.new(study, study.projects).perform
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert !investigation.subscribed?(current_person)
    assert !study.subscribed?(current_person)
    assert !assay.subscribed?(current_person)

    # changing projects associated with the investigation
    investigation.reload
    disable_authorization_checks do
      investigation.projects = [proj]
      investigation.save
    end

    assert SetSubscriptionsForItemJob.new(investigation, [proj]).exists?
    SetSubscriptionsForItemJob.new(investigation, [proj]).perform

    investigation.reload
    study.reload
    assay.reload
    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)
  end

  test 'should remove subscriptions for a study and an assay associated with this study when updating the investigation associating with this study' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?
    investigation = Factory(:investigation, projects: [proj])
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(assay, assay.projects).exists?
    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?
    SetSubscriptionsForItemJob.new(assay, assay.projects).perform
    SetSubscriptionsForItemJob.new(study, study.projects).perform
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)

    # changing investigation associated with the study
    study.reload
    new_investigation = Factory(:investigation)
    disable_authorization_checks do
      study.investigation = new_investigation
      study.save
    end

    assert RemoveSubscriptionsForItemJob.new(assay, [proj]).exists?
    assert RemoveSubscriptionsForItemJob.new(study, [proj]).exists?
    assert !RemoveSubscriptionsForItemJob.new(investigation, [proj]).exists?
    RemoveSubscriptionsForItemJob.new(assay, [proj]).perform
    RemoveSubscriptionsForItemJob.new(study, [proj]).perform

    investigation.reload
    study.reload
    assay.reload
    assert investigation.subscribed?(current_person)
    assert !study.subscribed?(current_person)
    assert !assay.subscribed?(current_person)
  end

  test 'should add subscriptions for a study and an assay associated with this study when updating the investigation associating with this study' do
    proj = Factory(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?
    investigation = Factory(:investigation, projects: [proj])
    study = Factory(:study, investigation: Factory(:investigation))
    assay = Factory(:assay, study: study, policy: Factory(:public_policy))

    assert SetSubscriptionsForItemJob.new(assay, assay.projects).exists?
    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    assert SetSubscriptionsForItemJob.new(investigation, investigation.projects).exists?
    SetSubscriptionsForItemJob.new(assay, assay.projects).perform
    SetSubscriptionsForItemJob.new(study, study.projects).perform
    SetSubscriptionsForItemJob.new(investigation, investigation.projects).perform

    assert investigation.subscribed?(current_person)
    assert !study.subscribed?(current_person)
    assert !assay.subscribed?(current_person)

    # changing investigation associated with the study
    study.reload
    disable_authorization_checks do
      study.investigation = investigation
      study.save
    end

    assert SetSubscriptionsForItemJob.new(assay, assay.projects).exists?
    assert SetSubscriptionsForItemJob.new(study, study.projects).exists?
    SetSubscriptionsForItemJob.new(assay, assay.projects).perform
    SetSubscriptionsForItemJob.new(study, study.projects).perform

    investigation.reload
    study.reload
    assay.reload
    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)
  end

  private

  def current_person
    User.current_user.person
  end
end
