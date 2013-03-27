require 'test_helper'

class PublishingPermissionsTest < ActiveSupport::TestCase
  fixtures :specimens

  test 'is_rejected?' do
    df = Factory(:data_file)
    assert !df.is_rejected?

    log = ResourcePublishLog.add_log(ResourcePublishLog::REJECTED, df)
    assert df.is_rejected?

    log.created_at=4.months.ago
    assert log.save
    assert !df.is_rejected?
  end

  test 'is_waiting_approval?' do
    User.with_current_user Factory(:user) do
      df = Factory(:data_file)
      assert !df.is_waiting_approval?

      log = ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, df)
      assert df.is_waiting_approval?

      log.created_at=4.months.ago
      assert log.save
      assert !df.is_waiting_approval?
    end
  end

  test 'gatekeeper_required?' do
    df = Factory(:data_file)
    assert !df.gatekeeper_required?

    gatekeeper = Factory(:gatekeeper)
    assert !df.gatekeeper_required?

    disable_authorization_checks { df.projects = gatekeeper.projects }
    df.reload
    assert df.gatekeeper_required?
  end

  test "is_published?" do
    User.with_current_user Factory(:user) do
      public_sop=Factory(:sop,:policy=>Factory(:public_policy,:access_type=>Policy::ACCESSIBLE))
      not_public_model=Factory(:model,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
      public_datafile=Factory(:data_file,:policy=>Factory(:public_policy))
      public_assay=Factory(:assay,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
      not_public_sample=Factory(:sample,:policy=>Factory(:all_sysmo_viewable_policy))

      assert public_sop.is_published?
      assert !not_public_model.is_published?
      assert public_datafile.is_published?
      assert public_assay.is_published?
      assert !not_public_sample.is_published?
    end
  end

  test "is_in_isa_publishable?" do
    assert Factory(:sop).is_in_isa_publishable?
    assert Factory(:model).is_in_isa_publishable?
    assert Factory(:data_file).is_in_isa_publishable?
    assert !Factory(:assay).is_in_isa_publishable?
    assert !Factory(:investigation).is_in_isa_publishable?
    assert !Factory(:study).is_in_isa_publishable?
    assert !Factory(:event).is_in_isa_publishable?
    assert !Factory(:publication).is_in_isa_publishable?
  end

  test "publish!" do
    user = Factory(:user)
    private_model=Factory(:model,:contributor=>user,:policy=>Factory(:public_policy,:access_type=>Policy::VISIBLE))
    User.with_current_user user do
      assert private_model.can_manage?,"Should be able to manage this model for the test to work"
      assert private_model.publish!
    end
    private_model.reload
    assert_equal Policy::ACCESSIBLE,private_model.policy.access_type
    assert_equal Policy::EVERYONE,private_model.policy.sharing_scope

  end

  test "publishable when item is manageable and is not yet published and gatekeeper is not required" do
    user = Factory(:user)
    User.with_current_user user do
      df = Factory(:data_file, :contributor => User.current_user)
      assert df.can_manage?,'This item must be manageable for the test to succeed'
      assert !df.is_published?,'This item must be not published for the test to succeed'
      assert !df.gatekeeper_required?,'This item must not require gatekeeper for the test to succeed'

      assert df.can_publish?,'This item should be publishable'
    end
  end

  test "publishable when item is manageable and is not yet published and gatekeeper is required and is not waiting for approval and is not rejected" do
    user = Factory(:user)
    User.with_current_user user do
      df = Factory(:data_file, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
      assert df.can_manage?,'This item must be manageable for the test to succeed'
      assert !df.is_published?,'This item must be not published for the test to succeed'
      assert df.gatekeeper_required?,'This item must require gatekeeper for the test to be meaningful'
      assert !df.is_waiting_approval?,'This item must require gatekeeper for the test to be meaningful'
      assert !df.is_rejected?,'This item must require gatekeeper for the test to be meaningful'

      assert df.can_publish?,'This item should be publishable'
    end
  end

  test "not publishable when item is not manageable" do
    user = Factory(:user)
    User.with_current_user user do
      df = Factory(:data_file, :policy => Factory(:all_sysmo_viewable_policy))
      assert !df.can_manage?,'This item must be manageable for the test to succeed'
      assert !df.is_published?,'This item must be not published for the test to be meaningful'
      assert !df.gatekeeper_required?,'This item must require gatekeeper for the test to be meaningful'

      assert !df.can_publish?,'This item should not be publishable'
    end
  end

  test "not publishable when item is already published" do
    user = Factory(:user)
    User.with_current_user user do
      df = Factory(:data_file, :policy => Factory(:public_policy))
      assert df.can_manage?,'This item must be manageable for the test to be meaningful'
      assert df.is_published?,'This item must be not published for the test to succeed'
      assert !df.gatekeeper_required?,'This item must require gatekeeper for the test to be meaningful'

      assert !df.can_publish?,'This item should not be publishable'
    end
  end

  test "not publishable when item is waiting for approval" do
    user = Factory(:user)
    User.with_current_user user do
      df = Factory(:data_file, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
      df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>User.current_user)
      assert df.can_manage?,'This item must be manageable for the test to be meaningful'
      assert !df.is_published?,'This item must be not published for the test to be meaningful'
      assert df.gatekeeper_required?,'This item must require gatekeeper for the test to succeed'
      assert df.is_waiting_approval?,'This item must be waiting for approval for the test to succeed'
      assert !df.is_rejected?,'This item must not be rejected for the test to be meaningful'

      assert !df.can_publish?,'This item should not be publishable'
    end
  end

  test "not publishable when item was rejected" do
    user = Factory(:user)
    User.with_current_user user do
      df = Factory(:data_file, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
      df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::REJECTED)
      assert df.can_manage?,'This item must be manageable for the test to be meaningful'
      assert !df.is_published?,'This item must be not published for the test to be meaningful'
      assert df.gatekeeper_required?,'This item must require gatekeeper for the test to succeed'
      assert !df.is_waiting_approval?,'This item must be waiting for approval for the test to be meaningful'
      assert df.is_rejected?,'This item must not be rejected for the test to succeed'

      assert !df.can_publish?,'This item should not be publishable'
    end
  end

  test "gatekeeper of asset can publish if they can manage it as well" do
      gatekeeper = Factory(:gatekeeper)
      datafile = Factory(:data_file, :projects => gatekeeper.projects)

      #adding manage right for gatekeeper
      User.with_current_user datafile.contributor do
        policy  = Factory(:policy)
        policy.permissions = [Factory(:permission, :contributor => gatekeeper, :access_type => Policy::MANAGING)]
        datafile.policy = policy
        datafile.save
      end

      User.with_current_user gatekeeper.user do
        ability = Ability.new(User.current_user)
        assert gatekeeper.is_gatekeeper_of?(datafile),'The gatekeeper must be the gatekeeper of the datafile for the test to succeed'
        assert datafile.can_manage?,'The datafile must be manageable for the test to succeed'

        assert ability.can? :publish, datafile
        assert datafile.can_publish?,'This datafile should be publishable'
      end
  end

  test "gatekeeper of asset can publish, if the asset is waiting for his approval" do
    gatekeeper = Factory(:gatekeeper)
    datafile = Factory(:data_file, :projects => gatekeeper.projects)
    datafile.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>datafile.contributor)

    User.with_current_user gatekeeper.user do
      ability = Ability.new(User.current_user)
      assert gatekeeper.is_gatekeeper_of?(datafile),'The gatekeeper must be the gatekeeper of datafile for the test to succeed'
      assert !datafile.can_manage?,'The datafile must be manageable for the test to be meaningful'
      assert datafile.is_waiting_approval?,'The datafile must be waiting for approval for the test to succeed'

      assert ability.can? :publish, datafile
      assert datafile.can_publish?,'This datafile should be publishable'
    end
  end

  test "gatekeeper can not publish asset which he is not the gatekeeper of" do
    gatekeeper = Factory(:gatekeeper)
    datafile = Factory(:data_file)
    datafile.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>datafile.contributor)

    User.with_current_user gatekeeper.user do
      ability = Ability.new(User.current_user)

      assert !gatekeeper.is_gatekeeper_of?(datafile),'The gatekeeper must not be the gatekeeper of datafile for the test to be succeed'
      assert datafile.is_waiting_approval?,'The datafile must be waiting for approval for the test to be meaningful'

      assert ability.cannot? :publish, datafile
      assert !datafile.can_publish?,'This datafile should not be publishable'
    end
  end

  test "gatekeeper of asset can not publish, if they can not manage and the asset is not waiting for his approval" do
    gatekeeper = Factory(:gatekeeper)
    datafile = Factory(:data_file, :projects => gatekeeper.projects)

    User.with_current_user gatekeeper.user do
      ability = Ability.new(gatekeeper.user)
      assert gatekeeper.is_gatekeeper_of?(datafile), 'The gatekeeper must be the gatekeeper of datafile for the test to be meaningful'
      assert !datafile.can_manage?, 'The datafile must not be manageable for the test to succeed'
      assert !datafile.is_waiting_approval?,'The datafile must be waiting for approval for the test to succeed'

      assert ability.cannot? :publish, datafile
      assert !datafile.can_publish?, 'This datafile should not be publishable'
    end
  end

  test 'disable authorization check for publishing_auth' do
      df = Factory(:data_file)
      assert_equal Policy::PRIVATE, df.policy.sharing_scope
      user = Factory(:user)
      User.with_current_user user do
        assert !df.can_publish?
      end

      disable_authorization_checks do
        df.policy.sharing_scope = Policy::EVERYONE
        assert df.save
        df.reload
        assert_equal Policy::EVERYONE, df.policy.sharing_scope
      end
    end
end