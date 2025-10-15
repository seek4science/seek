require 'test_helper'

class PublishingPermissionsTest < ActiveSupport::TestCase

  test 'is_rejected?' do
    items_for_publishing_tests.each do |item|
      item = FactoryBot.create(:data_file)
      refute item.is_rejected?

      ResourcePublishLog.add_log(ResourcePublishLog::REJECTED, item)
      assert item.is_rejected?
    end
  end

  test 'is_updated_since_be_rejected?' do
    person = FactoryBot.create(:person, project:FactoryBot.create(:asset_gatekeeper).projects.first)

    User.with_current_user person.user do
      items_for_publishing_tests(person).each do |item|
        refute item.is_rejected?

        ResourcePublishLog.add_log(ResourcePublishLog::REJECTED, item)
        assert item.is_rejected?

        item.title = 'new title'
        item.updated_at = Time.now + 1.day
        item.save!

        assert item.is_updated_since_be_rejected?
        assert item.can_publish?
      end
    end

  end

  test 'is_waiting_approval?' do
    items_for_publishing_tests.each do |item|
      refute item.is_waiting_approval?
      refute item.is_waiting_approval?(User.current_user)

      log = ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, item)
      assert item.is_waiting_approval?
      assert item.is_waiting_approval?(User.current_user)
    end
  end

  test 'gatekeeper_required?' do
    items_for_publishing_tests.each do |item|
      refute item.gatekeeper_required?

      gatekeeper = FactoryBot.create(:asset_gatekeeper)
      refute item.gatekeeper_required?

      case item.class.name
      when 'Study', 'Assay', 'ObservationUnit'
        disable_authorization_checks { item.investigation.projects = gatekeeper.projects }
      else
        disable_authorization_checks { item.projects = gatekeeper.projects }
      end

      item.reload
      assert item.gatekeeper_required?
    end

  end

  test 'is_published?' do
    User.with_current_user FactoryBot.create(:user) do
      public_sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy, access_type: Policy::ACCESSIBLE))
      not_public_model = FactoryBot.create(:model, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
      public_datafile = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
      public_assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
      public_obs_unit = FactoryBot.create(:observation_unit, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))

      assert public_sop.is_published?
      refute not_public_model.is_published?
      assert public_datafile.is_published?
      assert public_assay.is_published?
      assert public_obs_unit.is_published?
    end
  end

  test 'is_in_isa_publishable?' do
    assert FactoryBot.create(:sop).is_in_isa_publishable?
    assert FactoryBot.create(:model).is_in_isa_publishable?
    assert FactoryBot.create(:data_file).is_in_isa_publishable?
    refute FactoryBot.create(:assay).is_in_isa_publishable?
    refute FactoryBot.create(:investigation).is_in_isa_publishable?
    refute FactoryBot.create(:study).is_in_isa_publishable?
    refute FactoryBot.create(:event).is_in_isa_publishable?
    refute FactoryBot.create(:publication).is_in_isa_publishable?
    refute FactoryBot.create(:observation_unit).is_in_isa_publishable?
  end

  test 'publishable when item is manageable and is not yet published and gatekeeper is not required' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      items_for_publishing_tests(user.person).each do |item|
        assert item.can_manage?, 'This item must be manageable for the test to succeed'
        refute item.is_published?, 'This item must be not published for the test to succeed'
        refute item.gatekeeper_required?, 'This item must not require gatekeeper for the test to succeed'

        assert item.can_publish?, 'This item should be publishable'
      end
    end
  end

  test 'publishable when item is manageable and is not yet published and gatekeeper is required and is not waiting for approval and is not rejected' do
    person = FactoryBot.create(:person, project:FactoryBot.create(:asset_gatekeeper).projects.first)
    User.with_current_user person.user do
      items_for_publishing_tests(person).each do |item|
        assert item.can_manage?, 'This item must be manageable for the test to succeed'
        refute item.is_published?, 'This item must be not published for the test to succeed'
        assert item.gatekeeper_required?, 'This item must require gatekeeper for the test to be meaningful'
        refute item.is_waiting_approval?(User.current_user), 'This item must not be waiting for approval for the test to be meaningful'
        refute item.is_rejected?, 'This item must require gatekeeper for the test to be meaningful'

        assert item.can_publish?, 'This item should be publishable'
      end
    end
  end

  test 'not publishable when item is not manageable' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      items_for_publishing_tests.each do |item|
        item.policy = FactoryBot.create(:all_sysmo_viewable_policy)
        disable_authorization_checks { item.save! }
        refute item.can_manage?, 'This item must be manageable for the test to succeed'
        refute item.is_published?, 'This item must be not published for the test to be meaningful'
        refute item.gatekeeper_required?, 'This item must require gatekeeper for the test to be meaningful'

        refute item.can_publish?, 'This item should not be publishable'
      end
    end
  end

  test 'not publishable when item is already published' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      items_for_publishing_tests.each do |item|
        item.policy = FactoryBot.create(:public_policy)
        disable_authorization_checks { item.save! }
        assert item.can_manage?, 'This item must be manageable for the test to be meaningful'
        assert item.is_published?, 'This item must be not published for the test to succeed'
        refute item.gatekeeper_required?, 'This item must require gatekeeper for the test to be meaningful'

        refute item.can_publish?, 'This item should not be publishable'
      end

    end
  end

  test 'not publishable when item is waiting for approval' do
    person = FactoryBot.create(:person,project: FactoryBot.create(:asset_gatekeeper).projects.first)
    User.with_current_user person.user do
      items_for_publishing_tests(person).each do |item|
        item.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: User.current_user)
        assert item.can_manage?, 'This item must be manageable for the test to be meaningful'
        refute item.is_published?, 'This item must be not published for the test to be meaningful'
        assert item.gatekeeper_required?, 'This item must require gatekeeper for the test to succeed'
        assert item.is_waiting_approval?(User.current_user), 'This item must be waiting for approval for the test to succeed'
        refute item.is_rejected?, 'This item must not be rejected for the test to be meaningful'

        refute item.can_publish?, 'This item should not be publishable'
      end
    end
  end

  test 'not publishable when item was rejected and but publishable again when item was updated' do
    person = FactoryBot.create(:person,project:FactoryBot.create(:asset_gatekeeper).projects.first)
    User.with_current_user person.user do
      items_for_publishing_tests(person).each do |item|
        item.resource_publish_logs.create(publish_state: ResourcePublishLog::REJECTED)
        assert item.can_manage?, 'This item must be manageable for the test to be meaningful'
        refute item.is_published?, 'This item must be not published for the test to be meaningful'
        assert item.gatekeeper_required?, 'This item must require gatekeeper for the test to succeed'
        refute item.is_waiting_approval?(User.current_user), 'This item must be waiting for approval for the test to be meaningful'
        assert item.is_rejected?, 'This item must not be rejected for the test to succeed'
        item.title = 'new title'
        item.updated_at = Time.now + 1.day
        item.save!
        assert item.is_updated_since_be_rejected?
        assert item.can_publish?, 'This item should be publishable after update'
      end
    end
  end

  test 'gatekeeper of asset can publish if they can manage it as well' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    User.with_current_user gatekeeper.user do
      items_for_publishing_tests(gatekeeper).each do |item|
        assert gatekeeper.is_asset_gatekeeper_of?(item), 'The gatekeeper must be the gatekeeper of the item for the test to succeed'
        assert item.can_manage?, 'The item must be manageable for the test to succeed'

        assert item.can_publish?, 'This item should be publishable'
      end
    end
  end

  test 'gatekeeper of asset can publish, if the asset is waiting for his approval' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person, project:gatekeeper.projects.first)
    items_for_publishing_tests(person).each do |item|
      item.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: item.contributor.user)

      User.with_current_user gatekeeper.user do
        assert gatekeeper.is_asset_gatekeeper_of?(item), 'The gatekeeper must be the gatekeeper of the item for the test to succeed'
        refute item.can_manage?, 'The item must be manageable for the test to be meaningful'
        assert item.is_waiting_approval?, 'The item must be waiting for approval for the test to succeed'

        assert item.can_publish?, 'This item should be publishable'
      end
    end
  end

  test 'gatekeeper can not publish asset which he is not the gatekeeper of' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    items_for_publishing_tests.each do |item|
      item.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: item.contributor.user)

      User.with_current_user gatekeeper.user do
        refute gatekeeper.is_asset_gatekeeper_of?(item), 'The gatekeeper must not be the gatekeeper of the item for the test to be succeed'
        assert item.is_waiting_approval?, 'The item must be waiting for approval for the test to be meaningful'

        refute item.can_publish?, 'This item should not be publishable'
      end
    end
  end

  test 'gatekeeper of asset can not publish, if they can not manage and the asset is not waiting for his approval' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)

    User.with_current_user gatekeeper.user do
      items_for_publishing_tests(person).each do |item|
        assert gatekeeper.is_asset_gatekeeper_of?(item), 'The gatekeeper must be the gatekeeper of the item for the test to be meaningful'
        refute item.can_manage?, 'The item must not be manageable for the test to succeed'
        refute item.is_waiting_approval?, 'The item must be waiting for approval for the test to succeed'

        refute item.can_publish?, 'This item should not be publishable'
      end
    end
  end

  test 'gatekeeper can not publish if the asset is already published' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)

    User.with_current_user gatekeeper.user do
      items_for_publishing_tests(gatekeeper).each do |item|
        item.policy = FactoryBot.create(:public_policy)
        disable_authorization_checks { item.save! }
        assert item.is_published?, 'This item must be already published for the test to succeed'
        assert gatekeeper.is_asset_gatekeeper_of?(item), 'The gatekeeper must be the gatekeeper of the item for the test to be meaningful'
        assert item.can_manage?, 'The item must not be manageable for the test to succeed'

        refute item.can_publish?, 'This item should not be publishable'
      end
    end
  end

  test 'publish! only when can_publish?' do
    user = FactoryBot.create(:user)
    df = FactoryBot.create(:data_file, contributor: user.person)
    User.with_current_user user do
      assert df.can_publish?
      assert df.publish!
    end

    refute df.can_publish?
    refute df.publish!
  end

  test 'publish! is performed when no gatekeeper is required' do
    user = FactoryBot.create(:user)
    User.with_current_user user do
      items_for_publishing_tests(user.person).each do |item|
        assert item.can_publish?, 'The item must be publishable'
        refute item.gatekeeper_required?, 'The gatekeeper must not be required for the test to succeed'
        refute item.is_published?, 'This item must not be published yet for the test to be meaningful'

        assert item.publish!
        assert item.is_published?, 'This item should be published now'
      end
    end
  end

  test 'publish! is performed when you are the gatekeeper of the item' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)
    items_for_publishing_tests(person).each do |item|
      item.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL)

      User.with_current_user gatekeeper.user do
        assert item.can_publish?, 'The item must be publishable for the test to succeed'
        assert item.gatekeeper_required?, 'The gatekeeper must not be required for the test to succeed'
        refute item.is_published?, 'This item must not be published yet for the test to be meaningful'

        assert item.publish!
        assert item.is_published?, 'This item should be published now'
      end
    end
  end

  test 'publish! is not performed when the gatekeeper is required and you are not the gatekeeper of the item' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = FactoryBot.create(:person,project:gatekeeper.projects.first)
    items_for_publishing_tests(person).each do |item|
      User.with_current_user person.user do
        assert item.can_publish?, 'The item must be publishable for the test to succeed'
        assert item.gatekeeper_required?, 'The gatekeeper must not be required for the test to succeed'
        refute person.is_asset_gatekeeper_of?(item), 'You are not the gatekeeper of this item for the test to succeed'
        refute item.is_published?, 'This item must not be published yet for the test to be meaningful'

        refute item.publish!
        refute item.is_published?, 'This item should not be published'
      end
    end
  end

  test 'add log after doing publish!' do
    person = FactoryBot.create(:person)
    User.with_current_user person.user do
      items_for_publishing_tests(person).each do |item|
        assert item.resource_publish_logs.empty?
        assert item.publish!
        assert_equal 1, item.resource_publish_logs.count
        log = item.resource_publish_logs.first
        assert_equal ResourcePublishLog::PUBLISHED, log.publish_state
      end
    end
  end

  test 'disable authorization check for publishing_auth' do
    user = FactoryBot.create(:user)
    items_for_publishing_tests.each do |item|
      assert_equal Policy::NO_ACCESS, item.policy.access_type

      User.with_current_user user do
        refute item.can_publish?
      end

      disable_authorization_checks do
        item.policy.access_type = Policy::ACCESSIBLE
        assert item.save
        item.reload
        assert_equal Policy::ACCESSIBLE, item.policy.access_type
      end
    end

  end

  test 'publishing should clear sharing scope' do
    items_for_publishing_tests.each do |item|
      item.policy = FactoryBot.create(:public_policy,sharing_scope:Policy::ALL_USERS)
      disable_authorization_checks { item.save! }
      assert_equal Policy::ALL_USERS, item.policy.sharing_scope
      User.with_current_user(item.contributor.user) do
        assert item.can_publish?
        item.publish!
        item.reload
        refute_equal Policy::ALL_USERS,item.policy.sharing_scope
      end
    end
  end

  private

  def items_for_publishing_tests(contributor = FactoryBot.create(:person))
    items = [:data_file, :sop, :document, :workflow, :investigation, :sample].collect do |type|
      FactoryBot.create(type, contributor: contributor, projects: contributor&.projects)
    end

    #projects handled differently
    study = FactoryBot.create(:study, contributor: contributor,
                              investigation: FactoryBot.create(:investigation, projects: contributor&.projects)
    )
    assay = FactoryBot.create(:assay, contributor: contributor, study:
      FactoryBot.create(:study, contributor: contributor, investigation: FactoryBot.create(:investigation, projects: contributor&.projects))
    )
    obs_unit = FactoryBot.create(:observation_unit, contributor: contributor, study:
      FactoryBot.create(:study, contributor: contributor, investigation: FactoryBot.create(:investigation, projects: contributor&.projects))
    )
    items | [study, assay, obs_unit]
    [obs_unit]
  end
end
