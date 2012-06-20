require 'test_helper'

class SubscriptionJobTest < ActiveSupport::TestCase
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
    assert !SubscriptionJob.exists?
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue SubscriptionJob.new
    end

    assert SubscriptionJob.exists?

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !SubscriptionJob.exists?,"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !SubscriptionJob.exists?,"Should ignore failed jobs"
  end

  test "add items to queue" do
      assert_difference("Delayed::Job.count",1) do
        assert_difference("SubscriptionQueue.count",2) do
          SubscriptionJob.add_items_to_queue [1,2]
        end
      end

      SubscriptionQueue.destroy_all
      Delayed::Job.destroy_all
      assert_difference("Delayed::Job.count",1) do
        assert_difference("SubscriptionQueue.count",1) do
          SubscriptionJob.add_items_to_queue nil
        end
      end
      assert_nil SubscriptionQueue.first.activity_log

      #add_items_to_queue from callback
      SubscriptionQueue.destroy_all
      Delayed::Job.destroy_all
      disable_authorization_checks do
        al =  ActivityLog.create(:activity_loggable => sops(:my_first_sop), :culprit => users(:owner_of_my_first_sop), :action => 'create')
        assert_equal 1, SubscriptionQueue.count
        assert_equal al.id, SubscriptionQueue.first.activity_log_id
        assert_equal 1, Delayed::Job.count
      end
   end

  test "perform" do
    SubscriptionQueue.destroy_all
    Delayed::Job.destroy_all
    person1 = Factory(:person)
    person2 = Factory(:person)
    sop = Factory(:sop, :policy => Factory(:public_policy))
    ProjectSubscription.create(:person_id => person1.id, :project_id => sop.projects.first.id, :frequency => 'immediately')
    ProjectSubscription.create(:person_id => person2.id, :project_id => sop.projects.first.id, :frequency => 'immediately')
    assert_emails 2 do
      disable_authorization_checks do
        ActivityLog.create(:activity_loggable => sop, :culprit => Factory(:user), :action => 'create')
      end
      SubscriptionJob.new.perform
    end
  end
end