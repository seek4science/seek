require 'test_helper'

class AuthLookupMaintenaceJobTest < ActiveSupport::TestCase

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
    #ensure a consistent initial state
    disable_authorization_checks do
      Seek::Util.authorized_types.each(&:destroy_all)
      Seek::Util.authorized_types.each(&:clear_lookup_table)
    end

    User.destroy_all
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

      #gets immmediately updated for anonymous user
      assert Document.lookup_table_consistent?(nil)

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

end