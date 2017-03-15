
require 'test_helper'

class PolicyBasedAuthTest < ActiveSupport::TestCase
  fixtures :all

  test 'has advanced permissions' do
    user = Factory(:user)
    User.current_user = user
    proj1 = Factory :project
    proj2 = Factory :project
    person1 = Factory :person
    person2 = Factory :person
    df = Factory :data_file, policy: Factory(:private_policy), contributor: user.person, projects: [proj1]

    assert !df.has_advanced_permissions?
    Factory(:permission, contributor: person1, access_type: Policy::EDITING, policy: df.policy)
    assert df.reload.has_advanced_permissions?

    model = Factory :model, policy: Factory(:public_policy), contributor: user.person, projects: [proj1, proj2]
    assert !model.reload.has_advanced_permissions?
    Factory(:permission, contributor: Factory(:institution), access_type: Policy::ACCESSIBLE, policy: model.policy)
    assert model.reload.has_advanced_permissions?

    # when having a sharing_scope policy of Policy::ALL_USERS it is concidered to have advanced permissions if any of the permissions do not relate to the projects associated with the resource (ISA or Asset))
    # this is a temporary work-around for the loss of the custom_permissions flag when defining a pre-canned permission of shared with sysmo, but editable/downloadable within mhy project
    assay = Factory :experimental_assay, policy: Factory(:all_sysmo_viewable_policy), contributor: user.person, study: Factory(:study, investigation: Factory(:investigation, projects: [proj1, proj2]))
    assay.policy.permissions << Factory(:permission, contributor: proj1, access_type: Policy::EDITING)
    assay.policy.permissions << Factory(:permission, contributor: proj2, access_type: Policy::EDITING)
    assay.save!
    assert !assay.reload.has_advanced_permissions?
    proj_permission = Factory(:permission, contributor: Factory(:project), access_type: Policy::EDITING)
    assay.policy.permissions << proj_permission
    assert assay.reload.has_advanced_permissions?
    assay.policy.permissions.delete(proj_permission)
    assay.save!
    assert !assay.reload.has_advanced_permissions?
    assay.policy.permissions << Factory(:permission, contributor: Factory(:project), access_type: Policy::VISIBLE)
    assert assay.reload.has_advanced_permissions?
  end

  test 'people within the same project can_see_hidden_item' do
    test_user = Factory(:user)
    datafile = Factory(:data_file, projects: test_user.person.projects, policy: Factory(:private_policy))
    assert !datafile.can_view?(test_user)
    assert datafile.can_see_hidden_item? test_user.person
  end

  test 'people in different project can_not_see_hidden_item' do
    test_user = Factory(:user)
    datafile = Factory(:data_file, policy: Factory(:private_policy))
    assert !datafile.can_view?(test_user)
    assert !datafile.can_see_hidden_item?(test_user.person)
  end

  test 'authorization_permissions' do
    with_config_value :auth_lookup_enabled, true do
      Sop.delete_all
      user = Factory(:person).user
      other_user = Factory :user
      sop = Factory :sop, contributor: user, policy: Factory(:editing_public_policy)
      Sop.clear_lookup_table

      sop.update_lookup_table(user)
      sop.update_lookup_table(other_user)

      permissions = sop.authorization_permissions user
      assert permissions.can_view
      assert permissions.can_download
      assert permissions.can_edit
      assert permissions.can_manage
      assert permissions.can_delete

      permissions = sop.authorization_permissions other_user
      assert permissions.can_view
      assert permissions.can_download
      assert permissions.can_edit
      assert !permissions.can_manage
      assert !permissions.can_delete
    end
  end

  test 'update lookup table' do
    with_config_value :auth_lookup_enabled, true do
      user = Factory :user
      other_user = Factory :user
      sop = Factory :sop, contributor: user, policy: Factory(:editing_public_policy)
      Sop.clear_lookup_table
      # check using the standard
      assert sop.authorized_for_view?(user)
      assert sop.authorized_for_download?(user)
      assert sop.authorized_for_edit?(user)
      assert sop.authorized_for_manage?(user)
      assert sop.authorized_for_delete?(user)

      assert sop.authorized_for_view?(other_user)
      assert sop.authorized_for_download?(other_user)
      assert sop.authorized_for_edit?(other_user)
      assert !sop.authorized_for_manage?(other_user)
      assert !sop.authorized_for_delete?(other_user)

      sop.update_lookup_table(user)
      sop.update_lookup_table(other_user)

      assert sop.authorized_for_view?(user)
      assert sop.authorized_for_download?(user)
      assert sop.authorized_for_edit?(user)
      assert sop.authorized_for_manage?(user)
      assert sop.authorized_for_delete?(user)

      assert sop.authorized_for_view?(other_user)
      assert sop.authorized_for_download?(other_user)
      assert sop.authorized_for_edit?(other_user)
      assert !sop.authorized_for_manage?(other_user)
      assert !sop.authorized_for_delete?(other_user)
    end
  end

  test 'lookup table counts' do
    with_config_value :auth_lookup_enabled, true do
      User.current_user = nil
      user = Factory :user
      disable_authorization_checks do
        Sop.clear_lookup_table
        assert_equal 0, Sop.lookup_count_for_user(user.id)
        sop = Factory :sop
        assert_equal 0, Sop.lookup_count_for_user(user.id)
        sop.update_lookup_table(user)
        assert_equal 1, Sop.lookup_count_for_user(user.id)
        assert sop.destroy
        assert_equal 0, Sop.lookup_count_for_user(user.id)
      end
    end
  end
end
