require 'test_helper'
#Authorization tests that are specific to public access
class SubscriptionTest < ActiveSupport::TestCase

  def setup
    User.current_user = Factory(:user)
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled=true
    Delayed::Job.destroy_all
  end

  def teardown
      Delayed::Job.destroy_all
      Seek::Config.email_enabled=@val
  end
  

  test 'subscribing and unsubscribing toggle subscribed?' do
    s = Factory(:subscribable)

    assert !s.subscribed?
    s.subscribe; s.save!; s.reload
    assert s.subscribed?

    s.unsubscribe; s.save!; s.reload
    assert !s.subscribed?

    another_person = Factory(:person)
    assert !s.subscribed?(another_person)
    s.subscribe(another_person); s.save!; s.reload
    assert s.subscribed?(another_person)
    s.unsubscribe(another_person); s.save!; s.reload
    assert !s.subscribed?(another_person)
  end

  test 'can subscribe to someone elses subscribable' do
    s = Factory(:subscribable, :contributor => Factory(:user))
    assert !s.subscribed?
    s.subscribe
    assert s.save
    assert s.subscribed?
  end

  test 'subscribers with a frequency of immediate are sent emails when activity is logged' do
    proj = Factory(:project)
    current_person.project_subscriptions.create :project => proj, :frequency => 'immediately'
    s = Factory(:subscribable, :projects => [Factory(:project), proj], :policy => Factory(:public_policy))
    s.subscribe; s.save!
    
    assert_emails(1) do
      al = Factory(:activity_log, :activity_loggable => s, :action => 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end


    other_guy = Factory(:person)
    other_guy.project_subscriptions.create :project => proj, :frequency => 'immediately'
    s.reload
    s.subscribe(other_guy); s.save!

    assert_emails(2) do
      al = Factory(:activity_log, :activity_loggable => s, :action => 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end
  end

  test 'subscribers without a frequency of immediate are not sent emails when activity is logged' do
    proj = Factory(:project)
    current_person.project_subscriptions.create :project => proj, :frequency => 'weekly'
    s = Factory(:subscribable, :projects =>[proj], :policy => Factory(:public_policy))
    s.subscribe; s.save!

    assert_no_emails do
      Factory(:activity_log, :activity_loggable => s, :action => 'update')
    end
  end

  test 'subscribers are not sent emails for items they cannot view' do
    proj = Factory(:project)
    current_person.project_subscriptions.create :project => proj, :frequency => 'immediately'
    s = Factory(:subscribable, :policy => Factory(:private_policy), :contributor => Factory(:user), :projects => [proj])

    assert_no_emails do
      User.with_current_user(s.contributor) do
        al = Factory(:activity_log, :activity_loggable => s, :action => 'update')
        SendImmediateEmailsJob.new(al.id).perform
      end
    end
  end

  test 'subscribers who do not receive notifications dont receive emails' do

    current_person.notifiee_info.receive_notifications = false
    current_person.notifiee_info.save!

    assert !current_person.receive_notifications?
    
    proj = Factory(:project)
    current_person.project_subscriptions.create :project => proj, :frequency => 'immediately'
    s = Factory(:subscribable, :projects => [proj], :policy => Factory(:public_policy))
    s.subscribe; s.save!

    assert_no_emails do
      al = Factory(:activity_log, :activity_loggable => s, :action => 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end

  end

  test 'subscribers who are not registered dont receive emails' do
    person = Factory(:person_in_project)
    proj = Factory(:project)
    s = Factory(:subscribable, :projects => [proj], :policy => Factory(:public_policy))    

    disable_authorization_checks do
      person.project_subscriptions.create :project => proj, :frequency => 'immediately'
      s.subscribe; s.save!
    end

    assert_no_emails do
      al = Factory(:activity_log, :activity_loggable => s, :action => 'update')
      SendImmediateEmailsJob.new(al.id).perform
    end

  end

  test 'set_default_subscriptions when one item is created' do
    proj = Factory(:project)
    current_person.project_subscriptions.create :project => proj, :frequency => 'weekly'
    assert Subscription.all.empty?

    s = Factory(:subscribable, :projects => [Factory(:project), proj], :policy => Factory(:public_policy))
    assert s.subscribed?(current_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'set_default_subscriptions when a study is created' do
    proj = Factory(:project)
    current_person.project_subscriptions.create :project => proj, :frequency => 'weekly'
    assert Subscription.all.empty?

    s = Factory(:study, :investigation => Factory(:investigation, :projects => [proj]), :policy => Factory(:public_policy))

    assert s.subscribed?(current_person)
    assert_equal 2, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'subscribe to all the items in a project when subscribing to that project' do
    proj = Factory(:project)
    s1 = Factory(:subscribable, :projects => [Factory(:project), proj], :policy => Factory(:public_policy))
    s2 = Factory(:subscribable, :projects => [Factory(:project), proj], :policy => Factory(:public_policy))

    assert !s1.subscribed?(current_person)
    assert !s2.subscribed?(current_person)

    current_person.project_subscriptions.create :project => proj, :frequency => 'weekly'

    s1.reload
    s2.reload
    assert s1.subscribed?(current_person)
    assert s2.subscribed?(current_person)
    assert_equal 2, current_person.subscriptions.count
    current_person.subscriptions.each do |s|
      assert_equal proj, s.project_subscription.project
    end
  end

  private

  def current_person
    User.current_user.person
  end
end
