require 'test_helper'

class AuthLookupMaintenaceJobTest < ActiveSupport::TestCase

  def setup
    #ensure a consistent initial state
    disable_authorization_checks do
      Seek::Util.authorized_types.each(&:destroy_all)
      Seek::Util.authorized_types.each(&:clear_lookup_table)
    end

    User.destroy_all
    AuthLookupUpdateQueue.destroy_all
  end

  test 'run period' do
    assert_equal 8.hours, AuthLookupMaintenanceJob::RUN_PERIOD
  end

  test 'priority' do
    assert_equal 3, AuthLookupMaintenanceJob.priority
  end

  test 'queue name' do
    assert_equal QueueNames::AUTH_LOOKUP, AuthLookupMaintenanceJob.queue_name
  end


  test 'check authlookup consistency' do

    p = FactoryBot.create(:person)
    p2 = FactoryBot.create(:person)
    u = FactoryBot.create(:brand_new_user)

    assert_nil u.person

    with_config_value(:auth_lookup_enabled, true) do
      assert AuthLookupUpdateQueue.queue_enabled?

      doc1 = FactoryBot.create(:document)
      doc2 = FactoryBot.create(:document)
      AuthLookupUpdateJob.perform_now

      assert Document.lookup_table_consistent?(p.user)
      assert Document.lookup_table_consistent?(p2.user)
      assert Document.lookup_table_consistent?(nil)

      assert_no_enqueued_jobs do
        assert_no_difference('AuthLookupUpdateQueue.count') do
          AuthLookupMaintenanceJob.perform_now
        end
      end

      # delete a record
      Document.lookup_class.where(user_id:p.user.id,asset_id:doc1.id).last.delete

      #duplicate a record
      Document.lookup_class.where(user_id:p2.user.id, asset_id:doc2.id).last.dup.save!

      refute Document.lookup_table_consistent?(p.user)
      refute Document.lookup_table_consistent?(p2.user)

      assert_enqueued_jobs(1) do
        assert_difference('AuthLookupUpdateQueue.count',1) do
          AuthLookupMaintenanceJob.perform_now
        end
      end

      # double check it will be fixed when the job runs
      AuthLookupUpdateJob.perform_now
      assert Document.lookup_table_consistent?(p.user)
      assert Document.lookup_table_consistent?(p2.user)
      assert Document.lookup_table_consistent?(nil)
    end

  end

  test 'test for anonymous user' do

    with_config_value(:auth_lookup_enabled, true) do
      assert AuthLookupUpdateQueue.queue_enabled?

      doc = FactoryBot.create(:document)
      AuthLookupUpdateJob.perform_now

      assert Document.lookup_table_consistent?(nil)

      # delete a record
      Document.lookup_class.where(user_id:0,asset_id:doc.id).last.delete

      refute Document.lookup_table_consistent?(nil)

      # queued after the user has been removed
      assert_enqueued_jobs(1) do
        assert_difference('AuthLookupUpdateQueue.count',1) do
          AuthLookupMaintenanceJob.perform_now
        end
      end

    end
  end

  test 'skip if user or person in the queue' do

    p = FactoryBot.create(:person)

    with_config_value(:auth_lookup_enabled, true) do
      assert AuthLookupUpdateQueue.queue_enabled?

      doc1 = FactoryBot.create(:document)
      AuthLookupUpdateJob.perform_now

      assert Document.lookup_table_consistent?(p.user)

      # delete a record
      Document.lookup_class.where(user_id:p.user.id,asset_id:doc1.id).last.delete

      refute Document.lookup_table_consistent?(p.user)

      refute AuthLookupUpdateQueue.any?
      AuthLookupUpdateQueue.create!(item: p.user)
      assert AuthLookupUpdateQueue.any?

      # nothing queued whilst user is queued
      assert_no_enqueued_jobs do
        assert_no_difference('AuthLookupUpdateQueue.count') do
          AuthLookupMaintenanceJob.perform_now
        end
      end

      AuthLookupUpdateQueue.destroy_all
      AuthLookupUpdateQueue.create!(item: p)
      assert AuthLookupUpdateQueue.any?

      # nothing queued whilst person is queued
      assert_no_enqueued_jobs do
        assert_no_difference('AuthLookupUpdateQueue.count') do
          AuthLookupMaintenanceJob.perform_now
        end
      end

      AuthLookupUpdateQueue.destroy_all
      refute AuthLookupUpdateQueue.any?
      #add another item to make sure it's only checking for user/person
      AuthLookupUpdateQueue.create!(item: FactoryBot.create(:sop))
      assert AuthLookupUpdateQueue.any?

      # queued after the user has been removed
      assert_enqueued_jobs(1) do
        assert_difference('AuthLookupUpdateQueue.count',1) do
          AuthLookupMaintenanceJob.perform_now
        end
      end

    end
  end

  test 'skip if particular type is on the queue' do
    p = FactoryBot.create(:person)

    with_config_value(:auth_lookup_enabled, true) do
      assert AuthLookupUpdateQueue.queue_enabled?

      doc1 = FactoryBot.create(:document)
      AuthLookupUpdateJob.perform_now

      assert Document.lookup_table_consistent?(p.user)

      # delete a record
      Document.lookup_class.where(user_id:p.user.id,asset_id:doc1.id).last.delete

      refute Document.lookup_table_consistent?(p.user)

      refute AuthLookupUpdateQueue.any?
      AuthLookupUpdateQueue.create!(item: doc1)
      assert AuthLookupUpdateQueue.any?

      # nothing queued whilst doc1 is queued
      assert_no_enqueued_jobs do
        assert_no_difference('AuthLookupUpdateQueue.count') do
          AuthLookupMaintenanceJob.perform_now
        end
      end

      AuthLookupUpdateQueue.destroy_all
      refute AuthLookupUpdateQueue.any?

      # queued after the doc1 has been removed
      assert_enqueued_jobs(1) do
        assert_difference('AuthLookupUpdateQueue.count',1) do
          AuthLookupMaintenanceJob.perform_now
        end
      end

    end
  end

  test 'checks each type' do
    p = FactoryBot.create(:person)

    with_config_value(:auth_lookup_enabled, true) do
      assert AuthLookupUpdateQueue.queue_enabled?

      doc = FactoryBot.create(:document)
      sample = FactoryBot.create(:sample)
      sop = FactoryBot.create(:sop)
      with_config_value(:auth_lookup_update_batch_size, 20) do
        AuthLookupUpdateJob.perform_now
      end

      assert Document.lookup_table_consistent?(p.user)
      assert Sample.lookup_table_consistent?(p.user)
      assert Sop.lookup_table_consistent?(p.user)

      # delete a record
      Document.lookup_class.where(user_id:p.user.id,asset_id:doc.id).last.delete
      Sample.lookup_class.where(user_id:p.user.id,asset_id:sample.id).last.delete
      Sop.lookup_class.where(user_id:p.user.id,asset_id:sop.id).last.delete

      refute Document.lookup_table_consistent?(p.user)
      refute Sample.lookup_table_consistent?(p.user)
      refute Sop.lookup_table_consistent?(p.user)

      assert_enqueued_jobs(3) do
        assert_difference('AuthLookupUpdateQueue.count',3) do
          AuthLookupMaintenanceJob.perform_now
        end
      end

      assert AuthLookupUpdateQueue.where(item: doc).any?
      assert AuthLookupUpdateQueue.where(item: sample).any?
      assert AuthLookupUpdateQueue.where(item: sop).any?
    end
  end

end