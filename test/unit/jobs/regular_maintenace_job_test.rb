require 'test_helper'

class RegularMaintenaceJobTest < ActiveSupport::TestCase
  def setup
    ContentBlob.destroy_all
  end

  test 'run period' do
    assert_equal 4.hours, RegularMaintenanceJob::RUN_PERIOD
  end

  test 'cleans content blobs' do
    assert_equal 8.hours, RegularMaintenanceJob::BLOB_GRACE_PERIOD
    to_go, keep1, keep2, keep3, keep4 = nil
    travel_to(9.hours.ago) do
      to_go = Factory(:content_blob)
      keep1 = Factory(:data_file).content_blob
      keep2 = Factory(:investigation).create_snapshot.content_blob
      keep3 = Factory(:strain_sample_type).content_blob
    end

    travel_to(7.hours.ago) do
      keep4 = Factory(:content_blob)
    end

    assert_difference('ContentBlob.count', -1) do
      RegularMaintenanceJob.perform_now
    end

    refute ContentBlob.exists?(to_go.id)
    assert ContentBlob.exists?(keep1.id)
    assert ContentBlob.exists?(keep2.id)
    assert ContentBlob.exists?(keep3.id)
    assert ContentBlob.exists?(keep4.id)
  end

  test 'remove old unregistered users' do
    assert_equal 1.week, RegularMaintenanceJob::USER_GRACE_PERIOD
    to_go, keep1, keep2 = nil
    travel_to(2.weeks.ago) do
      to_go = Factory(:brand_new_user)
      assert_nil to_go.person
      keep1 = Factory(:person).user
    end

    travel_to(5.days.ago) do
      keep2 = Factory(:brand_new_user)
      assert_nil keep2.person
    end

    assert_difference('User.count', -1) do
      RegularMaintenanceJob.perform_now
    end

    refute User.exists?(to_go.id)
    assert User.exists?(keep1.id)
    assert User.exists?(keep2.id)
  end

  test 'resend activation emails' do
    User.destroy_all
    assert_equal 3, RegularMaintenanceJob::MAX_ACTIVATION_EMAILS
    assert_equal 4.hours, RegularMaintenanceJob::RESEND_ACTIVATION_EMAIL_DELAY
    # person 1 - not activated, and 2 messages sent 5 hours ago
    person1 = Factory(:not_activated_person)
    refute person1.user.active?
    travel_to(5.hours.ago) do
      ActivationEmailMessageLog.log_activation_email(person1)
      ActivationEmailMessageLog.log_activation_email(person1)
    end

    # person 2 - not activated, but 3 messages sent over 1 day ago
    person2 = Factory(:not_activated_person)
    travel_to(2.days.ago) do
      ActivationEmailMessageLog.log_activation_email(person2)
      ActivationEmailMessageLog.log_activation_email(person2)
      ActivationEmailMessageLog.log_activation_email(person2)
    end

    # person 3 - not activated, but 2 message sent, one 1 days ago but the latest 1 hour ago
    person3 = Factory(:not_activated_person)
    travel_to(1.day.ago) do
      ActivationEmailMessageLog.log_activation_email(person3)
    end
    travel_to(1.hour.ago) do
      ActivationEmailMessageLog.log_activation_email(person3)
    end

    # person 4 - not activated, and no message logs
    person4 = Factory(:not_activated_person)

    # person5 - an activated person, with no logs
    person5 = Factory(:person)
    assert person5.user.active?

    # an invalid user with missing person id, to test it is protected against
    user = Factory(:brand_new_user,person_id:Person.last.id+1)

    # only person 1 and person 4 should have emails resent
    assert_enqueued_emails(2) do
      assert_difference('ActivationEmailMessageLog.count', 2) do
        RegularMaintenanceJob.perform_now
      end
    end

    logs = ActivationEmailMessageLog.last(2)
    assert_equal [person1, person4].sort, logs.collect(&:subject).sort

    # running again should have no effect, as those due another email need to wait
    assert_enqueued_emails(0) do
      assert_no_difference('ActivationEmailMessageLog.count') do
        RegularMaintenanceJob.perform_now
      end
    end

    # again in 5 hours forward, and person 3 and person 4 should get one, person1 has had the 3 max
    travel(5.hours) do
      assert_enqueued_emails(2) do
        assert_difference('ActivationEmailMessageLog.count', 2) do
          RegularMaintenanceJob.perform_now
        end
      end
    end
    
    logs = ActivationEmailMessageLog.last(2)
    assert_equal [person3, person4].sort, logs.collect(&:subject).sort
  end

  test 'check authlookup consistency' do
    #ensure a consistent initial state
    disable_authorization_checks do
      Seek::Util.authorized_types.each(&:destroy_all)
      Seek::Util.authorized_types.each(&:clear_lookup_table)
    end

    User.destroy_all
    p = Factory(:person)
    p2 = Factory(:person)
    u = Factory(:brand_new_user)

    assert_nil u.person

    with_config_value(:auth_lookup_enabled, true) do
      assert AuthLookupUpdateQueue.queue_enabled?

      doc1 = Factory(:document)
      doc2 = Factory(:document)
      AuthLookupUpdateJob.perform_now

      assert Document.lookup_table_consistent?(p.user)
      assert Document.lookup_table_consistent?(p2.user)
      assert Document.lookup_table_consistent?(nil)

      assert_no_enqueued_jobs do
        assert_no_difference('AuthLookupUpdateQueue.count') do
          RegularMaintenanceJob.perform_now
        end
      end

      # delete a record
      Document.lookup_class.where(user_id:p.user.id,asset_id:doc1.id).last.delete

      #duplicate a record
      Document.lookup_class.where(user_id:p2.user.id, asset_id:doc2.id).last.dup.save!

      refute Document.lookup_table_consistent?(p.user)
      refute Document.lookup_table_consistent?(p2.user)

      #gets immmediately updated for anonymous user
      assert Document.lookup_table_consistent?(nil)

      assert_enqueued_jobs(1) do
        assert_difference('AuthLookupUpdateQueue.count',1) do
          RegularMaintenanceJob.perform_now
        end
      end

      # double check it will be fixed when the job runs
      AuthLookupUpdateJob.perform_now
      assert Document.lookup_table_consistent?(p.user)
      assert Document.lookup_table_consistent?(p2.user)
      assert Document.lookup_table_consistent?(nil)
    end


  end
end
