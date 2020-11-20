require 'test_helper'
class ActivityLogTest < ActiveSupport::TestCase
  test 'duplicates' do
    df = Factory :data_file
    sop = Factory :sop

    df_log_1 = Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files', created_at: 2.hour.ago
    df_log_2 = Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files', created_at: 1.hour.ago
    df_log_3 = Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files', created_at: 1.minute.ago
    df_log_4 = Factory :activity_log, activity_loggable: df, controller_name: 'data_files', action: 'download'
    df_log_5 = Factory :activity_log, activity_loggable: df, controller_name: 'data_files', action: 'download'

    sop_log_1 = Factory :activity_log, activity_loggable: sop, controller_name: 'sops', action: 'create', created_at: 2.hour.ago
    sop_log_2 = Factory :activity_log, activity_loggable: sop, controller_name: 'sops', action: 'create', created_at: 1.hour.ago
    sop_log_3 = Factory :activity_log, activity_loggable: sop, controller_name: 'sops', action: 'create', created_at: 2.minute.ago
    sop_log_4 = Factory :activity_log, activity_loggable: sop, controller_name: 'sops', action: 'show'
    sop_log_5 = Factory :activity_log, activity_loggable: sop, controller_name: 'sops', action: 'show'

    assert_equal 2, ActivityLog.duplicates('create').length
    assert_equal 1, ActivityLog.duplicates('download').length
    assert_equal 1, ActivityLog.duplicates('show').length
  end

  test 'remove duplicates' do
    df = Factory :data_file
    sop = Factory :sop

    df_log_1 = Factory :activity_log, activity_loggable: df, action: 'create', created_at: 2.hour.ago
    df_log_2 = Factory :activity_log, activity_loggable: df, action: 'create', created_at: 1.hour.ago
    df_log_3 = Factory :activity_log, activity_loggable: df, action: 'create', created_at: 1.minute.ago
    df_log_4 = Factory :activity_log, activity_loggable: df, action: 'download'
    df_log_5 = Factory :activity_log, activity_loggable: df, action: 'download'

    sop_log_1 = Factory :activity_log, activity_loggable: sop, action: 'create', created_at: 2.hour.ago
    sop_log_2 = Factory :activity_log, activity_loggable: sop, action: 'create', created_at: 1.hour.ago
    sop_log_3 = Factory :activity_log, activity_loggable: sop, action: 'create', created_at: 2.minute.ago
    sop_log_4 = Factory :activity_log, activity_loggable: sop, action: 'show'
    sop_log_5 = Factory :activity_log, activity_loggable: sop, action: 'show'

    assert_difference('ActivityLog.count', -4) do
      ActivityLog.remove_duplicate_creates
    end

    all = ActivityLog.all
    assert all.include?(df_log_1)
    assert all.include?(df_log_4)
    assert all.include?(df_log_5)
    assert !all.include?(df_log_2)
    assert !all.include?(df_log_3)

    all = ActivityLog.all
    assert all.include?(sop_log_1)
    assert all.include?(sop_log_4)
    assert all.include?(sop_log_5)
    assert !all.include?(sop_log_2)
    assert !all.include?(sop_log_3)
  end

  test 'no spider' do
    sop = Factory(:sop)
    al1 = Factory(:activity_log, activity_loggable: sop, user_agent: nil)
    al2 = Factory(:activity_log, activity_loggable: sop, user_agent: 'Mozilla')
    al3 = Factory(:activity_log, activity_loggable: sop, user_agent: 'Some spIder')
    logs = ActivityLog.no_spider

    assert_includes logs, al1
    assert_includes logs, al2
    refute_includes logs, al3
  end

  test 'can render link?' do
    disable_authorization_checks do
      public = Factory(:public_document)
      private = Factory(:private_document)
      public_log = Factory(:activity_log, activity_loggable: public, action: 'create', created_at: 2.hour.ago)
      private_log = Factory(:activity_log, activity_loggable: private, action: 'create', created_at: 2.hour.ago)

      assert public_log.can_render_link?
      refute private_log.can_render_link?

      public.destroy!

      refute public_log.reload.can_render_link?

      assay = Factory(:assay, policy: Factory(:publicly_viewable_policy))
      snapshot = assay.create_snapshot
      snapshot_log = Factory(:activity_log, activity_loggable: snapshot, action: 'create', created_at: 2.hour.ago)

      assert snapshot_log.can_render_link?

      assay.destroy!

      refute snapshot_log.reload.can_render_link?

      public2 = Factory(:public_document)
      version = public2.latest_version
      version_log = Factory(:activity_log, activity_loggable: version, action: 'create', created_at: 2.hour.ago)
      assert version_log.can_render_link?

      public2.destroy!

      refute version_log.reload.can_render_link?
    end
  end
end
