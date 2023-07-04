require 'test_helper'

class PublishingPermissionsTest < ActiveSupport::TestCase

  test 'is_rejected?' do
    df = FactoryBot.create(:data_file)
    assert !df.is_rejected?

    ResourcePublishLog.add_log(ResourcePublishLog::REJECTED, df)
    assert df.is_rejected?

  end

  test 'is_updated_since_be_rejected?' do
    person = FactoryBot.create(:person, project:FactoryBot.create(:asset_gatekeeper).projects.first)

    User.with_current_user person.user do
      df = FactoryBot.create(:data_file, contributor: person, projects: person.projects)
      assert !df.is_rejected?

      ResourcePublishLog.add_log(ResourcePublishLog::REJECTED, df)
      assert df.is_rejected?

      df.title = 'new title'
      df.updated_at = Time.now + 1.day
      df.save!

      assert df.is_updated_since_be_rejected?
      assert df.can_publish?
    end

  end

  test 'is_waiting_approval?' do
    User.with_current_user FactoryBot.create(:user) do
      df = FactoryBot.create(:data_file)
      assert !df.is_waiting_approval?
      assert !df.is_waiting_approval?(User.current_user)

      log = ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, df)
      assert df.is_waiting_approval?
      assert df.is_waiting_approval?(User.current_user)

    end
  end

  test 'gatekeeper_required?' do
    df = FactoryBot.create(:data_file)
    assert !df.gatekeeper_required?

    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    assert !df.gatekeeper_required?

    disable_authorization_checks { df.projects = gatekeeper.projects }
    df.reload
    assert df.gatekeeper_required?
  end

  test 'is_published?' do
    User.with_current_user FactoryBot.create(:user) do
      public_sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy, access_type: Policy::ACCESSIBLE))
      not_public_model = FactoryBot.create(:model, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
      public_datafile = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
      public_assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))

      assert public_sop.is_published?
      assert !not_public_model.is_published?
      assert public_datafile.is_published?
      assert public_assay.is_published?
    end
  end

  test 'is_in_isa_publishable?' do
    assert FactoryBot.create(:sop).is_in_isa_publishable?
    assert FactoryBot.create(:model).is_in_isa_publishable?
    assert FactoryBot.create(:data_file).is_in_isa_publishable?
    assert !FactoryBot.create(:assay).is_in_isa_publishable?
    assert !FactoryBot.create(:investigation).is_in_isa_publishable?
    assert !FactoryBot.create(:study).is_in_isa_publishable?
    assert !FactoryBot.create(:event).is_in_isa_publishable?
    assert !FactoryBot.create(:publication).is_in_isa_publishable?
  end

  test 'publishable when item is manageable and is not yet published and gatekeeper is not required' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      df = FactoryBot.create(:data_file, contributor: user.person)
      assert df.can_manage?, 'This item must be manageable for the test to succeed'
      assert !df.is_published?, 'This item must be not published for the test to succeed'
      assert !df.gatekeeper_required?, 'This item must not require gatekeeper for the test to succeed'

      assert df.can_publish?, 'This item should be publishable'
    end
  end

  test 'publishable when item is manageable and is not yet published and gatekeeper is required and is not waiting for approval and is not rejected' do
    person = FactoryBot.create(:person, project:FactoryBot.create(:asset_gatekeeper).projects.first)
    User.with_current_user person.user do
      df = FactoryBot.create(:data_file, contributor: person, projects: person.projects)
      assert df.can_manage?, 'This item must be manageable for the test to succeed'
      refute df.is_published?, 'This item must be not published for the test to succeed'
      assert df.gatekeeper_required?, 'This item must require gatekeeper for the test to be meaningful'
      refute df.is_waiting_approval?(User.current_user), 'This item must not be waiting for approval for the test to be meaningful'
      refute df.is_rejected?, 'This item must require gatekeeper for the test to be meaningful'

      assert df.can_publish?, 'This item should be publishable'
    end
  end

  test 'not publishable when item is not manageable' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      df = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_viewable_policy))
      assert !df.can_manage?, 'This item must be manageable for the test to succeed'
      assert !df.is_published?, 'This item must be not published for the test to be meaningful'
      assert !df.gatekeeper_required?, 'This item must require gatekeeper for the test to be meaningful'

      assert !df.can_publish?, 'This item should not be publishable'
    end
  end

  test 'not publishable when item is already published' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      df = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
      assert df.can_manage?, 'This item must be manageable for the test to be meaningful'
      assert df.is_published?, 'This item must be not published for the test to succeed'
      assert !df.gatekeeper_required?, 'This item must require gatekeeper for the test to be meaningful'

      assert !df.can_publish?, 'This item should not be publishable'
    end
  end

  test 'not publishable when item is waiting for approval' do
    person = FactoryBot.create(:person,project: FactoryBot.create(:asset_gatekeeper).projects.first)
    User.with_current_user person.user do
      df = FactoryBot.create( :data_file, contributor: person, projects: person.projects )
      df.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: User.current_user)
      assert df.can_manage?, 'This item must be manageable for the test to be meaningful'
      refute df.is_published?, 'This item must be not published for the test to be meaningful'
      assert df.gatekeeper_required?, 'This item must require gatekeeper for the test to succeed'
      assert df.is_waiting_approval?(User.current_user), 'This item must be waiting for approval for the test to succeed'
      refute df.is_rejected?, 'This item must not be rejected for the test to be meaningful'

      refute df.can_publish?, 'This item should not be publishable'
    end
  end

  test 'not publishable when item was rejected and but publishable again when item was updated' do
    person = FactoryBot.create(:person,project:FactoryBot.create(:asset_gatekeeper).projects.first)
    df = FactoryBot.create(:data_file, contributor: person, projects:person.projects )
    User.with_current_user person.user do
      df.resource_publish_logs.create(publish_state: ResourcePublishLog::REJECTED)
      assert df.can_manage?, 'This item must be manageable for the test to be meaningful'
      refute df.is_published?, 'This item must be not published for the test to be meaningful'
      assert df.gatekeeper_required?, 'This item must require gatekeeper for the test to succeed'
      refute df.is_waiting_approval?(User.current_user), 'This item must be waiting for approval for the test to be meaningful'
      assert df.is_rejected?, 'This item must not be rejected for the test to succeed'
      df.title = 'new title'
      df.updated_at = Time.now + 1.day
      df.save!
      assert df.is_updated_since_be_rejected?
      assert df.can_publish?, 'This item should be publishable after update'
    end
  end

  test 'gatekeeper of asset can publish if they can manage it as well' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    datafile = FactoryBot.create(:data_file, projects: gatekeeper.projects, contributor: gatekeeper)

    User.with_current_user gatekeeper.user do
      assert gatekeeper.is_asset_gatekeeper_of?(datafile), 'The gatekeeper must be the gatekeeper of the datafile for the test to succeed'
      assert datafile.can_manage?, 'The datafile must be manageable for the test to succeed'

      assert datafile.can_publish?, 'This datafile should be publishable'
    end
  end

  test 'gatekeeper of asset can publish, if the asset is waiting for his approval' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)
    datafile = FactoryBot.create(:data_file, projects: gatekeeper.projects, contributor:person)
    datafile.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: datafile.contributor.user)

    User.with_current_user gatekeeper.user do
      assert gatekeeper.is_asset_gatekeeper_of?(datafile), 'The gatekeeper must be the gatekeeper of datafile for the test to succeed'
      assert !datafile.can_manage?, 'The datafile must be manageable for the test to be meaningful'
      assert datafile.is_waiting_approval?, 'The datafile must be waiting for approval for the test to succeed'

      assert datafile.can_publish?, 'This datafile should be publishable'
    end
  end

  test 'gatekeeper can not publish asset which he is not the gatekeeper of' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    datafile = FactoryBot.create(:data_file)
    datafile.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: datafile.contributor.user)

    User.with_current_user gatekeeper.user do
      assert !gatekeeper.is_asset_gatekeeper_of?(datafile), 'The gatekeeper must not be the gatekeeper of datafile for the test to be succeed'
      assert datafile.is_waiting_approval?, 'The datafile must be waiting for approval for the test to be meaningful'

      assert !datafile.can_publish?, 'This datafile should not be publishable'
    end
  end

  test 'gatekeeper of asset can not publish, if they can not manage and the asset is not waiting for his approval' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)
    datafile = FactoryBot.create(:data_file, contributor:person)

    User.with_current_user gatekeeper.user do
      assert gatekeeper.is_asset_gatekeeper_of?(datafile), 'The gatekeeper must be the gatekeeper of datafile for the test to be meaningful'
      refute datafile.can_manage?, 'The datafile must not be manageable for the test to succeed'
      refute datafile.is_waiting_approval?, 'The datafile must be waiting for approval for the test to succeed'

      refute datafile.can_publish?, 'This datafile should not be publishable'
    end
  end

  test 'gatekeeper can not publish if the asset is already published' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    datafile = FactoryBot.create(:data_file, projects: gatekeeper.projects,
                                   policy: FactoryBot.create(:public_policy), contributor: gatekeeper)

    User.with_current_user gatekeeper.user do
      assert datafile.is_published?, 'This datafile must be already published for the test to succeed'
      assert gatekeeper.is_asset_gatekeeper_of?(datafile), 'The gatekeeper must be the gatekeeper of datafile for the test to be meaningful'
      assert datafile.can_manage?, 'The datafile must not be manageable for the test to succeed'

      assert !datafile.can_publish?, 'This datafile should not be publishable'
    end
  end

  test 'publish! only when can_publish?' do
    user = FactoryBot.create(:user)
    df = FactoryBot.create(:data_file, contributor: user.person)
    User.with_current_user user do
      assert df.can_publish?
      assert df.publish!
    end

    assert !df.can_publish?
    assert !df.publish!
  end

  test 'publish! is performed when no gatekeeper is required' do
    user = FactoryBot.create(:user)
    df = FactoryBot.create(:data_file, contributor: user.person)
    User.with_current_user user do
      assert df.can_publish?, 'The datafile must be publishable'
      assert !df.gatekeeper_required?, 'The gatekeeper must not be required for the test to succeed'
      assert !df.is_published?, 'This datafile must not be published yet for the test to be meaningful'

      assert df.publish!
      assert df.is_published?, 'This datafile should be published now'
    end
  end

  test 'publish! is performed when you are the gatekeeper of the item' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)
    df = FactoryBot.create(:data_file, projects: person.projects, contributor:person)
    df.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL)

    User.with_current_user gatekeeper.user do
      assert df.can_publish?, 'The datafile must be publishable for the test to succeed'
      assert df.gatekeeper_required?, 'The gatekeeper must not be required for the test to succeed'
      refute df.is_published?, 'This datafile must not be published yet for the test to be meaningful'

      assert df.publish!
      assert df.is_published?, 'This datafile should be published now'
    end
  end

  test 'publish! is not performed when the gatekeeper is required and you are not the gatekeeper of the item' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)
    df = FactoryBot.create(:data_file, projects: person.projects, contributor: person)

    User.with_current_user person.user do
      assert df.can_publish?, 'The datafile must be publishable for the test to succeed'
      assert df.gatekeeper_required?, 'The gatekeeper must not be required for the test to succeed'
      refute person.is_asset_gatekeeper_of?(df), 'You are not the gatekeeper of this datafile for the test to succeed'
      refute df.is_published?, 'This datafile must not be published yet for the test to be meaningful'

      refute df.publish!
      refute df.is_published?, 'This datafile should not be published'
    end
  end

  test 'add log after doing publish!' do
    person = FactoryBot.create(:person)
    df = FactoryBot.create(:data_file, contributor: person)
    User.with_current_user person.user do
      assert df.resource_publish_logs.empty?
      assert df.publish!
      assert_equal 1, df.resource_publish_logs.count
      log = df.resource_publish_logs.first
      assert_equal ResourcePublishLog::PUBLISHED, log.publish_state
    end
  end

  test 'disable authorization check for publishing_auth' do
    df = FactoryBot.create(:data_file)
    assert_equal Policy::NO_ACCESS, df.policy.access_type
    user = FactoryBot.create(:user)
    User.with_current_user user do
      assert !df.can_publish?
    end

    disable_authorization_checks do
      df.policy.access_type = Policy::ACCESSIBLE
      assert df.save
      df.reload
      assert_equal Policy::ACCESSIBLE, df.policy.access_type
    end
  end

  test 'publishing should clear sharing scope' do
    df = FactoryBot.create(:data_file,policy:FactoryBot.create(:public_policy,sharing_scope:Policy::ALL_USERS))
    assert_equal Policy::ALL_USERS,df.policy.sharing_scope
    User.with_current_user(df.contributor.user) do
      assert df.can_publish?
      df.publish!
      df.reload
      refute_equal Policy::ALL_USERS,df.policy.sharing_scope
    end
  end
end
