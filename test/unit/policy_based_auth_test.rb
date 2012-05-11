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

end