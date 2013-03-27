require 'test_helper'

class PublishingPermissionsTest < ActiveSupport::TestCase
  fixtures :specimens

  test 'is_rejected' do
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

  test "publish" do
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


    test "a person who is not an asset manager, who can manage the item, should not be able to publish the items, which hasn't been set to published" do
      person_can_manage = Factory(:person)
      gatekeeper = Factory(:gatekeeper)
      datafile = Factory(:data_file, :projects => gatekeeper.projects, :policy => Factory(:policy))
      Factory(:permission, :contributor => person_can_manage, :access_type => Policy::MANAGING, :policy => datafile.policy)

      User.with_current_user person_can_manage.user do
        assert datafile.can_manage?
        assert !datafile.can_publish?

        ability = Ability.new(person_can_manage.user)
        assert person_can_manage.roles.empty?
        assert ability.cannot? :manage_asset, datafile
        assert ability.cannot? :manage, datafile
        assert ability.cannot? :publish, datafile
      end
    end

    test "gatekeeper can publish items inside their project, only if they can manage it as well" do
      gatekeeper = Factory(:person, :roles => ['gatekeeper'])
      datafile = Factory(:data_file, :projects => gatekeeper.projects)

      #adding manage right for gatekeeper
      User.with_current_user datafile.contributor do
        policy  = Factory(:policy)
        policy.permissions = [Factory(:permission, :contributor => gatekeeper, :access_type => Policy::MANAGING)]
        datafile.policy = policy
        datafile.save
      end

      ability = Ability.new(gatekeeper.user)
      assert ability.can? :publish, datafile

      User.with_current_user gatekeeper.user do
        assert datafile.can_manage?
        assert datafile.can_publish?
      end
    end

    test "gatekeeper can not publish items inside their project, if they can not manage it" do
      gatekeeper = Factory(:person, :roles => ['gatekeeper'])
      datafile = Factory(:data_file, :projects => gatekeeper.projects)

      ability = Ability.new(gatekeeper.user)
      assert ability.cannot? :publish, datafile

      User.with_current_user gatekeeper.user do
        assert !datafile.can_manage?
        assert !datafile.can_publish?
      end
    end


    test "gatekeeper can not publish items outside their project" do
      gatekeeper = Factory(:person, :roles => ['gatekeeper'])
      datafile = Factory(:data_file)

      ability = Ability.new(gatekeeper.user)
      assert ability.cannot? :publish, datafile

      User.with_current_user gatekeeper.user do
        assert !datafile.can_publish?
      end
    end

    test "asset manager can manage the items inside their projects, but can not publish the items, which hasn't been set to published" do
      project = Factory(:project)
      work_group = Factory(:work_group, :project => project)

      asset_manager = Factory(:asset_manager, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
      gatekeeper = Factory(:gatekeeper, :group_memberships => [Factory(:group_membership, :work_group => work_group)])

      datafile = Factory(:data_file, :projects => asset_manager.projects, :policy => Factory(:all_sysmo_viewable_policy))

      User.with_current_user asset_manager.user do
        assert datafile.can_manage?
        assert !datafile.can_publish?

        ability = Ability.new(asset_manager.user)
        assert asset_manager.is_asset_manager?
        assert ability.can? :manage_asset, datafile
        assert ability.cannot? :publish, datafile
      end
    end

    test "manager should be able to publish if the projects have no gatekeepers" do
      person_can_manage = Factory(:person)
      datafile = Factory(:data_file, :projects => person_can_manage.projects, :policy => Factory(:policy))
      permission = Factory(:permission, :contributor => person_can_manage, :access_type => Policy::MANAGING, :policy => datafile.policy)


      User.with_current_user person_can_manage.user do
        assert datafile.gatekeepers.empty?
        assert datafile.can_manage?
        assert datafile.can_publish?
      end
    end

    test "can_publish for new asset" do
      #gatekeeper can publish
      gatekeeper = Factory(:gatekeeper)
      User.with_current_user gatekeeper.user do
        specimen = Specimen.new(:title => 'test1', :strain => Factory(:strain), :lab_internal_number => '1234', :projects => gatekeeper.projects, :policy => Policy.new(:sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
        assert specimen.can_publish?
        assert specimen.save
      end

      #contributor can not publish if projects associated with asset have gatekeepers
      User.with_current_user Factory(:user) do
        specimen = Specimen.new(:title => 'test2',
                                :strain => Factory(:strain),
                                :lab_internal_number => '1234',
                                :projects => gatekeeper.projects,
                                :policy => Policy.new(:sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
        assert !specimen.gatekeepers.empty?
        assert !specimen.can_publish?
        assert specimen.save
      end

      #contributor can publish if projects associated with asset have no gatekeepers
      User.with_current_user Factory(:user) do
        specimen = Specimen.new(:title => 'test3', :strain => Factory(:strain), :lab_internal_number => '1234', :projects => [Factory(:project)], :policy => Policy.new(:sharing_scope => Policy::EVERYONE, :access_type => Policy::ACCESSIBLE))
        assert specimen.gatekeepers.empty?
        assert specimen.can_publish?
        assert specimen.save
      end
    end

    test "can_publish when updating asset" do
      #gatekeeper can publish
      gatekeeper = Factory(:gatekeeper)
      User.with_current_user gatekeeper.user do
        specimen = Factory(:specimen, :projects => gatekeeper.projects, :contributor => gatekeeper)
        specimen.policy.sharing_scope = Policy::EVERYONE
        assert specimen.can_publish?
        assert specimen.save
      end

      work_group = Factory(:work_group, :project => gatekeeper.projects.first)
      contributor = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
      #contributor can not publish if projects associated with asset have gatekeepers
      User.with_current_user contributor.user do
        specimen = Factory(:specimen, :projects => gatekeeper.projects, :contributor => contributor)
        specimen.policy.sharing_scope = Policy::EVERYONE
        assert !specimen.can_publish?
        assert specimen.save
      end

      #contributor can publish if projects associated with asset have no gatekeepers
      User.with_current_user contributor.user do
        specimen = Factory(:specimen, :contributor => contributor)
        specimen.policy.sharing_scope = Policy::EVERYONE
        assert specimen.can_publish?
        assert specimen.save
      end

      #contributor can publish if asset was already published
      specimen = specimens(:public_specimen)
      User.with_current_user specimen.contributor do
        assert !specimen.gatekeepers.empty?
        assert !specimen.contributor.person.is_gatekeeper?
        assert_equal Policy::EVERYONE, specimen.policy.sharing_scope
        specimen.policy.sharing_scope = Policy::EVERYONE
        assert specimen.can_publish?
        assert specimen.save
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