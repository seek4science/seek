require 'test_helper'

class PolicyBasedAuthTest < ActiveSupport::TestCase
  fixtures :all

  test "has advanced permissions" do
    user = Factory(:user)
    User.current_user = user
    proj1=Factory :project
    proj2=Factory :project
    person1 = Factory :person
    person2 = Factory :person
    df = Factory :data_file, :policy => Factory(:private_policy), :contributor => user.person,:projects=>[proj1]

    assert !df.has_advanced_permissions?
    Factory(:permission,:contributor=>person1,:access_type=>Policy::EDITING, :policy => df.policy)
    assert df.has_advanced_permissions?

    model = Factory :model,:policy=>Factory(:public_policy),:contributor=>user.person,:projects=>[proj1,proj2]
    assert !model.has_advanced_permissions?
    Factory(:permission,:contributor=>Factory(:institution),:access_type=>Policy::ACCESSIBLE, :policy => model.policy)
    assert model.has_advanced_permissions?

    #when having a sharing_scope policy of Policy::ALL_SYSMO_USERS it is concidered to have advanced permissions if any of the permissions do not relate to the projects associated with the resource (ISA or Asset))
    #this is a temporary work-around for the loss of the custom_permissions flag when defining a pre-canned permission of shared with sysmo, but editable/downloadable within mhy project
    assay = Factory :experimental_assay,:policy=>Factory(:all_sysmo_viewable_policy),:contributor=>user.person,:study=>Factory(:study, :investigation=>Factory(:investigation,:projects=>[proj1,proj2]))
    assay.policy.permissions << Factory(:permission,:contributor=>proj1,:access_type=>Policy::EDITING)
    assay.policy.permissions << Factory(:permission,:contributor=>proj2,:access_type=>Policy::EDITING)
    assay.save!
    assert !assay.has_advanced_permissions?
    proj_permission = Factory(:permission,:contributor=>Factory(:project),:access_type=>Policy::EDITING)
    assay.policy.permissions << proj_permission
    assert assay.has_advanced_permissions?
    assay.policy.permissions.delete(proj_permission)
    assay.save!
    assert !assay.has_advanced_permissions?
    assay.policy.permissions << Factory(:permission,:contributor=>Factory(:project),:access_type=>Policy::VISIBLE)
    assert assay.has_advanced_permissions?
  end

  test "should cache" do
    datafile = data_files(:picture)
    user = users(:quentin)
    User.with_current_user user do
      Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
        cache_key = datafile.cache_keys user, action
        assert_nil Rails.cache.read(cache_key)

        is_authorized = datafile.send "can_#{action}?"
        assert_equal is_authorized, (Rails.cache.read(cache_key) == :true)
      end
    end
  end

  test "should create the new cache key when updating an asset" do
    datafile = Factory(:data_file)
    user = datafile.contributor
    cache_key = {}
    User.with_current_user user do
      Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
          cache_key["#{action}"] = datafile.cache_keys user, action
          assert_nil Rails.cache.read(cache_key["#{action}"])
          is_authorized = datafile.send "can_#{action}?"
          assert_equal is_authorized, (Rails.cache.read(cache_key["#{action}"]) == :true)
      end

      #delay 2 second to get the new updated_at when updating the datafile
      sleep(2)

      #update the datafile
      datafile.title = 'blabla'
      datafile.save
      datafile.reload

      Acts::Authorized::AUTHORIZATION_ACTIONS.each do |action|
          updated_cache_key = datafile.cache_keys user, action
          assert_not_equal cache_key["#{action}"], updated_cache_key
          is_authorized = datafile.send "can_#{action}?"
          assert_equal is_authorized, (Rails.cache.read(updated_cache_key) == :true)
      end
    end
  end

  test "should invalidate the cache when changing creators of an item" do
    test_user = Factory(:user)
    datafile = Factory(:data_file, :projects => test_user.person.projects, :creators => [test_user.person])
    assert datafile.can_edit?test_user

    sleep(2)

    User.with_current_user datafile.contributor do
      #update the datafile creators
      datafile.creators=[]
      datafile.save
      datafile.reload
    end

    assert !datafile.can_edit?(test_user)
  end

  test "should invalidate the cache when changing the person roles" do
    admin = Factory(:admin)
    asset_manager = Factory(:asset_manager)
    datafile = Factory(:data_file, :projects => asset_manager.projects, :policy => Factory(:public_policy, :access_type => Policy::VISIBLE))

    assert datafile.can_manage?asset_manager.user

    sleep(2)

    User.with_current_user admin.user do
      asset_manager.is_asset_manager = false
      asset_manager.save
      asset_manager.reload
      assert !asset_manager.is_asset_manager?
    end

    assert !datafile.can_manage?(asset_manager.user)
  end

  test "should invalidate the cache when updating policy of an asset" do
    test_user = Factory(:user)
    datafile = Factory(:data_file, :projects => test_user.person.projects, :policy => Factory(:public_policy))
    assert datafile.can_view?test_user

    sleep(2)

    User.with_current_user datafile.contributor do
      #update the policy
      datafile.policy.sharing_scope = Policy::PRIVATE
      datafile.policy.access_type = Policy::NO_ACCESS
      datafile.save
      datafile.reload
    end

    assert !datafile.can_view?(test_user)
  end

  test "should invalidate the cache when updating permissions of an asset" do
      test_user = Factory(:user)
      datafile = Factory(:data_file, :projects => test_user.person.projects, :policy => Factory(:private_policy))
      assert !datafile.can_view?(test_user)
      assert !(Rails.cache.read(datafile.cache_keys(test_user, "view")) == :true)

      sleep(2)

      User.with_current_user datafile.contributor do
        #update the permissions
        datafile.policy.permissions << Factory(:permission, :contributor => test_user.person, :access_type => Policy::VISIBLE)
        datafile.save
        datafile.reload
      end

      assert datafile.can_view?(test_user)
      assert (Rails.cache.read(datafile.cache_keys(test_user, "view")) == :true)
  end

  test "should invalidate the cache when updating work_groups of a person" do
        test_user = Factory(:user)
        #set up a 'share within projects' policy
        policy = Factory(:private_policy)
        permission = Factory(:permission, :contributor => test_user.person.projects.first, :access_type => Policy::ACCESSIBLE)
        policy.permissions << permission

        datafile = Factory(:data_file, :projects => test_user.person.projects, :policy => policy)
        assert datafile.can_download?(test_user)
        assert (Rails.cache.read(datafile.cache_keys(test_user, "download")) == :true)

        sleep(2)

        User.with_current_user Factory(:admin).user do
          #update work_groups of the test_user person
          test_user.person.group_memberships = [Factory(:group_membership)]
          test_user.person.save
          test_user.person.reload
          test_user.reload
        end

        assert !datafile.can_download?(test_user)
        assert !(Rails.cache.read(datafile.cache_keys(test_user, "download")) == :true)
  end

  test "should invalidate the cache when updating favourite_groups" do
    test_user = Factory(:user)
    datafile = Factory(:data_file)

    #set up a 'share within favourite' permission
    favourite_group = Factory(:favourite_group, :user => datafile.contributor)
    Factory(:favourite_group_membership, :person => test_user.person, :favourite_group => favourite_group)
    favourite_group.save

    Factory(:permission, :contributor => favourite_group, :access_type => Policy::DETERMINED_BY_GROUP, :policy => datafile.policy)

    assert_equal favourite_group.favourite_group_memberships.first, test_user.person.favourite_group_memberships.first
    assert_equal datafile.policy.permissions.first.contributor, favourite_group
    assert datafile.can_view?(test_user)
    assert (Rails.cache.read(datafile.cache_keys(test_user, "view")) == :true)

    sleep(2)

    User.with_current_user datafile.contributor do
      #exclude test_user person out of favourite group
      test_user.person.favourite_group_memberships.first.destroy
      test_user.person.reload
    end

    assert favourite_group.favourite_group_memberships.empty?
    assert !datafile.can_view?(test_user)
    assert !(Rails.cache.read(datafile.cache_keys(test_user, "view")) == :true)
  end
end