require 'test_helper'
# Authorization tests that are specific to public access
class SubscriptionTest < ActiveSupport::TestCase

  def setup
    User.current_user = FactoryBot.create(:user)
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
  end

  def teardown
    Seek::Config.email_enabled = @val
  end

  test 'for_susbscribable' do
    p = User.current_user.person
    p2 = FactoryBot.create :person
    sop = FactoryBot.create :sop
    sop2 = FactoryBot.create :sop
    assay = FactoryBot.create :assay
    assay2 = FactoryBot.create :assay
    FactoryBot.create :subscription, person: p, subscribable: sop
    FactoryBot.create :subscription, person: p2, subscribable: sop
    FactoryBot.create :subscription, person: p, subscribable: sop2
    FactoryBot.create :subscription, person: p, subscribable: assay
    FactoryBot.create :subscription, person: p, subscribable: assay2

    assert_equal 2, Subscription.for_subscribable(sop).count
    assert_equal [sop, sop], Subscription.for_subscribable(sop).collect(&:subscribable)
    assert_equal [assay], Subscription.for_subscribable(assay).collect(&:subscribable)
    assert_equal [sop], p.subscriptions.for_subscribable(sop).collect(&:subscribable)
  end

  test 'subscribing and unsubscribing toggle subscribed?' do
    s = FactoryBot.create(:subscribable)

    refute s.subscribed?
    disable_authorization_checks { s.subscribe }
    s.reload
    assert s.subscribed?

    disable_authorization_checks { s.unsubscribe }
    s.reload
    refute s.subscribed?

    another_person = FactoryBot.create(:person)
    refute s.subscribed?(another_person)
    disable_authorization_checks { s.subscribe(another_person) }
    s.reload
    assert s.subscribed?(another_person)
    disable_authorization_checks { s.unsubscribe(another_person) }
    s.reload
    refute s.subscribed?(another_person)
  end

  test 'can subscribe to someone elses subscribable' do

    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      s = FactoryBot.create(:subscribable, contributor: person)
      refute s.subscribed?
      disable_authorization_checks { s.subscribe }
      assert s.save
      assert s.subscribed?
    end

  end

  test 'subscribers with a frequency of immediate are sent emails when activity is logged' do
    proj = FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj)
    person.add_to_project_and_institution(FactoryBot.create(:project),FactoryBot.create(:institution))
    s = FactoryBot.create(:subscribable, projects: person.projects, policy: FactoryBot.create(:public_policy), contributor:person)

    disable_authorization_checks do
      current_person.project_subscriptions.create project: proj, frequency: 'immediately'
      s.subscribe
    end

    assert_enqueued_emails(1) do
      al = FactoryBot.create(:activity_log, activity_loggable: s, action: 'update')
      ImmediateSubscriptionEmailJob.perform_now(al)
    end

    other_guy = FactoryBot.create(:person)
    disable_authorization_checks do
      other_guy.project_subscriptions.create project: proj, frequency: 'immediately'
      s.reload
      s.subscribe(other_guy)
    end

    assert_enqueued_emails(2) do
      al = FactoryBot.create(:activity_log, activity_loggable: s, action: 'update')
      ImmediateSubscriptionEmailJob.perform_now(al)
    end
  end

  test 'subscribers without a frequency of immediate are not sent emails when activity is logged' do
    proj = FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    s = FactoryBot.create(:subscribable, projects: [proj], policy: FactoryBot.create(:public_policy),contributor:person)
    disable_authorization_checks { s.subscribe }

    assert_no_emails do
      FactoryBot.create(:activity_log, activity_loggable: s, action: 'update')
    end
  end

  test 'subscribers are not sent emails for items they cannot view' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    current_person.project_subscriptions.create project: proj, frequency: 'immediately'
    s = FactoryBot.create(:subscribable, policy: FactoryBot.create(:private_policy), contributor: person, projects: [proj])

    assert_no_emails do
      User.with_current_user(person) do
        al = FactoryBot.create(:activity_log, activity_loggable: s, action: 'update')
        ImmediateSubscriptionEmailJob.perform_now(al)
      end
    end
  end

  test 'subscribers who do not receive notifications dont receive emails' do
    current_person.reload
    current_person.notifiee_info.receive_notifications = false
    current_person.notifiee_info.save!
    current_person.reload

    refute current_person.receive_notifications?

    proj = FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj)
    current_person.project_subscriptions.create project: proj, frequency: 'immediately'
    s = FactoryBot.create(:subscribable, projects: [proj], policy: FactoryBot.create(:public_policy),contributor:person)
    disable_authorization_checks { s.subscribe }

    assert_no_emails do
      al = FactoryBot.create(:activity_log, activity_loggable: s, action: 'update')
      ImmediateSubscriptionEmailJob.perform_now(al)
    end
  end

  test 'subscribers who are not registered dont receive emails' do
    person = FactoryBot.create(:person_in_project)
    proj = FactoryBot.create(:project)
    other_person = FactoryBot.create(:person,project:proj)
    s = FactoryBot.create(:subscribable, projects: [proj], policy: FactoryBot.create(:public_policy),contributor:other_person)

    disable_authorization_checks do
      person.project_subscriptions.create project: proj, frequency: 'immediately'
      s.subscribe
    end

    assert_no_emails do
      al = FactoryBot.create(:activity_log, activity_loggable: s, action: 'update')
      ImmediateSubscriptionEmailJob.perform_now(al)
    end
  end

  test 'set_default_subscriptions when one item is created' do
    proj = current_person.projects.first
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    s = nil
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      s = FactoryBot.create(:subscribable, projects: [proj], policy: FactoryBot.create(:public_policy),contributor:current_person)
    end
    SetSubscriptionsForItemJob.perform_now(s, s.projects)

    assert s.subscribed?(current_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'set_default_subscriptions when a study is created' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    investigation = nil
    study = nil
    assert_enqueued_jobs(2, only: SetSubscriptionsForItemJob) do
      investigation = FactoryBot.create(:investigation, contributor: person, projects: [proj])
      study = FactoryBot.create(:study, contributor: person, investigation: investigation, policy: FactoryBot.create(:public_policy))
    end

    SetSubscriptionsForItemJob.perform_now(study, study.projects)
    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)

    assert study.subscribed?(current_person)
    assert investigation.subscribed?(current_person)
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'update subscriptions when changing a study associated to an assay' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2, FactoryBot.create(:institution))
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    investigation = nil
    study = nil
    assay = nil
    assert_enqueued_jobs(3, only: SetSubscriptionsForItemJob) do
      assay = FactoryBot.create(:assay, contributor: person, policy: FactoryBot.create(:public_policy))
      study = assay.study
      investigation = assay.investigation
    end

    SetSubscriptionsForItemJob.perform_now(assay, assay.projects)
    SetSubscriptionsForItemJob.perform_now(study, study.projects)
    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)

    assert assay.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert investigation.subscribed?(current_person)
    assert_equal proj, current_person.subscriptions.first.project_subscription.project

    # changing study
    assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [assay, [proj]]) do
      assay.study = FactoryBot.create(:study, contributor: person, investigation: FactoryBot.create(:investigation, contributor: person, projects: [project2]))
      disable_authorization_checks { assay.save }
    end
    RemoveSubscriptionsForItemJob.perform_now(assay, [proj])

    assay.reload
    refute assay.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert investigation.subscribed?(current_person)
  end

  test 'subscribe to all the items in a project when subscribing to that project' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    s1 = FactoryBot.create(:subscribable, projects: [proj], policy: FactoryBot.create(:public_policy),contributor:person)
    s2 = FactoryBot.create(:subscribable, projects: [proj], policy: FactoryBot.create(:public_policy),contributor:person)

    refute s1.subscribed?(current_person)
    refute s2.subscribed?(current_person)

    project_subscription = current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    ProjectSubscriptionJob.perform_now(project_subscription)
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
    proj = current_person.projects.first
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    projects = [proj]
    s = nil
    assert_enqueued_jobs(1, only: SetSubscriptionsForItemJob) do
      s = FactoryBot.create(:subscribable, projects: projects, policy: FactoryBot.create(:public_policy), contributor:current_person)
    end

    SetSubscriptionsForItemJob.perform_now(s, s.projects)

    assert s.subscribed?(current_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project

    # changing projects associated with the item
    updated_project = FactoryBot.create(:project)
    current_person.add_to_project_and_institution(updated_project,FactoryBot.create(:institution))

    assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [s, [projects.first]]) do
      assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [s, [updated_project]]) do
        disable_authorization_checks do
          s.projects = [updated_project]
          s.save
        end
      end
    end
    s.reload

    RemoveSubscriptionsForItemJob.perform_now(s, [projects.first])
    SetSubscriptionsForItemJob.perform_now(s, [updated_project])

    assert_equal 1, s.projects.count
    assert_equal updated_project, s.projects.first

    # should no longer subscribe to this item because of changing project
    refute s.subscribed?(current_person)
  end

  test 'should update subscription when associating the project to the item and a person subscribed to this project' do
    s = nil
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      s = FactoryBot.create(:subscribable, policy: FactoryBot.create(:public_policy))
    end
    project = s.projects.first

    SetSubscriptionsForItemJob.perform_now(s, s.projects)

    refute s.subscribed?(current_person)

    # changing projects associated with the item
    proj = FactoryBot.create(:project)
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'

    assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [s, [proj]]) do
      disable_authorization_checks do
        s.projects << proj
        s.save
      end
    end

    SetSubscriptionsForItemJob.perform_now(s, [proj])

    s.reload
    assert s.subscribed?(current_person)
  end

  test 'should update subscription when associating multiple projects to the item and a person subscribed to this project' do
    s = data_files(:picture)
    assert_equal 1, s.projects.count
    project = s.projects.first

    refute s.subscribed?(current_person)

    # changing projects associated with the item
    proj1 = FactoryBot.create(:project)
    proj2 = FactoryBot.create(:project)
    current_person.project_subscriptions.create project: proj1, frequency: 'weekly'
    current_person.project_subscriptions.create project: proj2, frequency: 'weekly'

    assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [s, [proj1]]) do
      assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [s, [proj2]]) do
        assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [s, [project]]) do
          disable_authorization_checks do
            s.projects = [proj1, proj2]
            s.save
          end
        end
      end
    end

    SetSubscriptionsForItemJob.perform_now(s, [proj1])
    SetSubscriptionsForItemJob.perform_now(s, [proj2])

    s.reload
    assert s.subscribed?(current_person)
  end

  test 'should remove subscriptions when updating the projects associating to an investigation' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2, FactoryBot.create(:institution))

    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    assay = nil
    assert_enqueued_jobs(3, only: SetSubscriptionsForItemJob) do
      assay = FactoryBot.create(:assay, contributor: person, policy: FactoryBot.create(:public_policy))
    end
    study = assay.study
    investigation = assay.investigation

    SetSubscriptionsForItemJob.perform_now(assay, assay.projects)
    SetSubscriptionsForItemJob.perform_now(study, study.projects)
    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)

    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)

    # changing projects associated with the investigation
    investigation.reload

    assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [investigation, investigation.projects]) do
      assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [investigation, [proj]]) do
        disable_authorization_checks do
          investigation.projects = [project2]
          investigation.save
        end
      end
    end

    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)
    RemoveSubscriptionsForItemJob.perform_now(investigation, [proj])

    investigation.reload
    study.reload
    assay.reload
    refute investigation.subscribed?(current_person)
    refute study.subscribed?(current_person)
    refute assay.subscribed?(current_person)
  end

  test 'should add subscriptions when updating the projects associating to an investigation' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2, FactoryBot.create(:institution))

    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?
    investigation = nil
    study = nil
    assay = nil
    assert_enqueued_jobs(3, only: SetSubscriptionsForItemJob) do
      investigation = FactoryBot.create(:investigation, contributor: person, projects: [project2])
      study = FactoryBot.create(:study, contributor: person, investigation: investigation)
      assay = FactoryBot.create(:assay, contributor: person, study: study, policy: FactoryBot.create(:public_policy))
    end
    SetSubscriptionsForItemJob.perform_now(assay, assay.projects)
    SetSubscriptionsForItemJob.perform_now(study, study.projects)
    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)

    refute investigation.subscribed?(current_person)
    refute study.subscribed?(current_person)
    refute assay.subscribed?(current_person)

    # changing projects associated with the investigation
    investigation.reload
    assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [investigation, [proj]]) do
      disable_authorization_checks do
        investigation.projects = [proj]
        investigation.save
      end
    end

    SetSubscriptionsForItemJob.perform_now(investigation, [proj])

    investigation.reload
    study.reload
    assay.reload
    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)
  end

  test 'should remove subscriptions for a study and an assay associated with this study when updating the investigation associating with this study' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2, FactoryBot.create(:institution))

    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    investigation = nil
    study = nil
    assay = nil
    assert_enqueued_jobs(3, only: SetSubscriptionsForItemJob) do
      assay = FactoryBot.create(:assay, contributor: person, policy: FactoryBot.create(:public_policy))
      study = assay.study
      investigation = assay.investigation
    end

    SetSubscriptionsForItemJob.perform_now(assay, assay.projects)
    SetSubscriptionsForItemJob.perform_now(study, study.projects)
    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)

    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)

    # changing investigation associated with the study
    study.reload
    assert_enqueued_jobs(2, only: RemoveSubscriptionsForItemJob) do
      assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [assay, [proj]]) do
        assert_enqueued_with(job: RemoveSubscriptionsForItemJob, args: [study, [proj]]) do
          new_investigation = FactoryBot.create(:investigation, contributor: person, projects: [project2])
          disable_authorization_checks do
            study.investigation = new_investigation
            study.save
          end
        end
      end
    end

    RemoveSubscriptionsForItemJob.perform_now(assay, [proj])
    RemoveSubscriptionsForItemJob.perform_now(study, [proj])

    investigation.reload
    study.reload
    assay.reload
    assert investigation.subscribed?(current_person)
    refute study.subscribed?(current_person)
    refute assay.subscribed?(current_person)
  end

  test 'should add subscriptions for a study and an assay associated with this study when updating the investigation associating with this study' do
    person = FactoryBot.create(:person)
    proj = person.projects.first
    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2, FactoryBot.create(:institution))

    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    assert Subscription.all.empty?

    investigation = nil
    study = nil
    assay = nil
    assert_enqueued_jobs(4, only: SetSubscriptionsForItemJob) do # 2 investigations, 1 study, 1 assay
      investigation = FactoryBot.create(:investigation, contributor: person, projects: [proj])
      study = FactoryBot.create(:study, contributor: person, investigation: FactoryBot.create(:investigation, contributor: person, projects: [project2]))
      assay = FactoryBot.create(:assay, contributor: person, study: study, policy: FactoryBot.create(:public_policy))
    end

    SetSubscriptionsForItemJob.perform_now(assay, assay.projects)
    SetSubscriptionsForItemJob.perform_now(study, study.projects)
    SetSubscriptionsForItemJob.perform_now(investigation, investigation.projects)

    assert investigation.subscribed?(current_person)
    refute study.subscribed?(current_person)
    refute assay.subscribed?(current_person)

    # changing investigation associated with the study
    study.reload
    assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [assay, investigation.projects]) do
      assert_enqueued_with(job: SetSubscriptionsForItemJob, args: [study, investigation.projects]) do
        disable_authorization_checks do
          study.investigation = investigation
          study.save!
        end
      end
    end

    investigation.reload
    assay.reload

    SetSubscriptionsForItemJob.perform_now(assay, assay.projects)
    SetSubscriptionsForItemJob.perform_now(study, study.projects)

    investigation.reload
    study.reload
    assay.reload
    assert investigation.subscribed?(current_person)
    assert study.subscribed?(current_person)
    assert assay.subscribed?(current_person)
  end

  test 'does not throw error if item does not exist when job is performed' do
    proj = current_person.projects.first

    # Arg format discovered by using "Job#send(:serialize)"
    serialized_args = [
      {'_aj_globalid' => "gid://seek/DataFile/#{DataFile.maximum(:id) + 1}"}, # Point to a non-existant data file
      [{'_aj_globalid' => "gid://seek/Project/#{proj.id}"}]
    ]

    assert_nothing_raised do
      x = SetSubscriptionsForItemJob.new
      x.serialized_arguments = serialized_args
      x.perform_now
    end
  end

  test 'does throw error if there is a genuine deserialization error' do
    proj = current_person.projects.first

    serialized_args = [
      {'_aj_globalid' => "gid://seek/Blooblaa/123"},
      [{'_aj_globalid' => "gid://seek/Project/#{proj.id}"}]
    ]

    assert_raises(ActiveJob::DeserializationError) do
      x = SetSubscriptionsForItemJob.new
      x.serialized_arguments = serialized_args
      x.perform_now
    end
  end

  private

  def current_person
    User.current_user.person
  end
end
