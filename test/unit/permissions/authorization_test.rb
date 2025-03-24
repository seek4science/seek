require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :all

  # ************************************************************************
  # this section tests individual helper methods within Authorization module
  # ************************************************************************

  def test_auth_on_asset_version
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    sop = FactoryBot.create :sop, contributor: user1.person, policy: FactoryBot.create(:private_policy)
    sop.policy.permissions << FactoryBot.create(:permission, policy: sop.policy, contributor: user2.person, access_type: Policy::VISIBLE)
    assert_equal 1, sop.versions.count
    sop_v = sop.versions.first

    assert_equal sop, sop_v.parent

    assert sop.can_manage?(user1)
    assert !sop.can_manage?(user2)
    assert sop.can_view?(user2)
    assert !sop.can_view?(nil)
    assert !sop.can_download?(user2)
    assert !sop.can_edit?(user2)

    assert sop_v.can_manage?(user1)
    assert !sop_v.can_manage?(user2)
    assert sop_v.can_view?(user2)
    assert !sop_v.can_view?(nil)
    assert !sop_v.can_download?(user2)
    assert !sop_v.can_edit?(user2)
  end

  # testing: is_member?(person_id, group_type, group_id)
  # member of any SysMO projects at all? (e.g. a "SysMO user": person who is associated with at least one project / institution ('workgroup'), not just a registered user)
  def test_is_member_associated_with_any_projects_true
    res = people(:random_userless_person).member?

    assert res, 'person associated with some SysMO projects was thought not to be associated with any'
  end

  # member of any SysMO projects at all?
  def test_is_member_associated_with_any_projects_false
    res = people(:person_not_associated_with_any_projects).member?

    assert !res, 'person not associated with any SysMO projects was thought to be a member of some'
  end

  # testing: access_type_allows_action?(action, access_type)

  def test_access_type_allows_action_no_access
    assert !Seek::Permissions::Authorization.access_type_allows_action?('view', Policy::NO_ACCESS), "'view' action should NOT have been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('download', Policy::NO_ACCESS), "'download' action should NOT have been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('edit', Policy::NO_ACCESS), "'edit' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('delete', Policy::NO_ACCESS), "'delete' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('manage', Policy::NO_ACCESS), "'manage' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
  end

  def test_access_type_allows_action_viewing_only
    assert Seek::Permissions::Authorization.access_type_allows_action?('view', Policy::VISIBLE), "'view' action should have been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('download', Policy::VISIBLE), "'download' action should NOT have been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('edit', Policy::VISIBLE), "'edit' action should have NOT been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('delete', Policy::VISIBLE), "'delete' action should have NOT been allowed with access_type set to 'Policy::VISIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('manage', Policy::VISIBLE), "'manage' action should have NOT been allowed with access_type set to 'Policy::VISIBLE'"
  end

  def test_access_type_allows_action_viewing_and_downloading_only
    assert Seek::Permissions::Authorization.access_type_allows_action?('view', Policy::ACCESSIBLE), "'view' action should have been allowed with access_type set to 'Policy::ACCESSIBLE' (cascading permissions)"
    assert Seek::Permissions::Authorization.access_type_allows_action?('download', Policy::ACCESSIBLE), "'download' action should have been allowed with access_type set to 'Policy::ACCESSIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('edit', Policy::ACCESSIBLE), "'edit' action should have NOT been allowed with access_type set to 'Policy::ACCESSIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('delete', Policy::ACCESSIBLE), "'delete' action should have NOT been allowed with access_type set to 'Policy::ACCESSIBLE'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('manage', Policy::ACCESSIBLE), "'manage' action should have NOT been allowed with access_type set to 'Policy::ACCESSIBLE'"
  end

  def test_access_type_allows_action_editing
    assert Seek::Permissions::Authorization.access_type_allows_action?('view', Policy::EDITING), "'view' action should have been allowed with access_type set to 'Policy::EDITING' (cascading permissions)"
    assert Seek::Permissions::Authorization.access_type_allows_action?('download', Policy::EDITING), "'download' action should have been allowed with access_type set to 'Policy::EDITING' (cascading permissions)"
    assert Seek::Permissions::Authorization.access_type_allows_action?('edit', Policy::EDITING), "'edit' action should have been allowed with access_type set to 'Policy::EDITING'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('delete', Policy::EDITING), "'delete' action should have NOT been allowed with access_type set to 'Policy::EDITING'"
    assert !Seek::Permissions::Authorization.access_type_allows_action?('manage', Policy::EDITING), "'manage' action should have NOT been allowed with access_type set to 'Policy::EDITING'"
  end

  def test_access_type_allows_action_managing
    assert Seek::Permissions::Authorization.access_type_allows_action?('view', Policy::MANAGING), "'view' action should have been allowed with access_type set to 'Policy::MANAGING' (cascading permissions)"
    assert Seek::Permissions::Authorization.access_type_allows_action?('download', Policy::MANAGING), "'download' action should have been allowed with access_type set to 'Policy::MANAGING' (cascading permissions)"
    assert Seek::Permissions::Authorization.access_type_allows_action?('edit', Policy::MANAGING), "'edit' action should have been allowed with access_type set to 'Policy::MANAGING'"
    assert Seek::Permissions::Authorization.access_type_allows_action?('delete', Policy::MANAGING), "'delete' action should have been allowed with access_type set to 'Policy::MANAGING'"
    assert Seek::Permissions::Authorization.access_type_allows_action?('manage', Policy::MANAGING), "'manage' action should have been allowed with access_type set to 'Policy::MANAGING'"
  end
  
  
  
  # ****************************************************************************
  # this section tests integration of individual helpers in Authorization module
  # ****************************************************************************

  # testing: authorized_by_policy?(policy, thing_asset, action, user_id, user_person_id)

  # 'everyone' policy
  def test_authorized_by_policy_fully_public_policy_anonymous_user
    res = temp_authorized_by_policy?(policies(:fully_public_policy), sops(:sop_with_fully_public_policy), 'download', nil, nil)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow not logged in users to perform 'download' where it should allow even 'edit'"
  end

  def test_authorized_by_policy_fully_public_policy_registered_user
    res = temp_authorized_by_policy?(policies(:fully_public_policy), sops(:sop_with_fully_public_policy), 'download', users(:registered_user_with_no_projects), users(:registered_user_with_no_projects).person)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow registered user to perform 'download' where it should allow even 'edit'"
  end

  def test_authorized_by_policy_fully_public_policy_sysmo_user
    res = temp_authorized_by_policy?(policies(:fully_public_policy), sops(:sop_with_fully_public_policy), 'download', users(:owner_of_my_first_sop), users(:owner_of_my_first_sop).person)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow SysMO user to perform 'download' where it should allow even 'edit'"
  end

  def test_authorized_for_model
    res = temp_authorized_by_policy?(policies(:policy_for_test_with_projects_institutions), models(:teusink), 'view', users(:model_owner), people(:person_for_model_owner))
    assert res, 'model_owner should be able to view his own model'
  end

  def test_not_authorized_for_model
    res = temp_authorized_by_policy?(policies(:policy_for_test_with_projects_institutions), models(:teusink), 'download', users(:quentin), users(:quentin).person)
    assert !res, 'Quentin should not be able to download that model'
  end

  # 'all SysMO users' policy
  def test_authorized_by_policy_all_sysmo_users_policy_anonymous_user
    res = temp_authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), sops(:sop_with_all_sysmo_users_policy), 'download', nil, nil)
    assert res, "policy with sharing_scope = 'Policy::ALL_USERS' wouldn't allow anonymous users to perform allowed action"
  end

  def test_authorized_by_policy_all_sysmo_users_policy_registered_user
    res = temp_authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), sops(:sop_with_all_sysmo_users_policy), 'download', users(:registered_user_with_no_projects), users(:registered_user_with_no_projects).person)
    assert res, "policy with sharing_scope = 'Policy::ALL_USERS' wouldn't allow registered user to perform allowed action"
  end

  def test_authorized_by_policy_all_sysmo_users_policy_sysmo_user
    res = temp_authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), sops(:sop_with_all_sysmo_users_policy), 'download', users(:owner_of_my_first_sop), users(:owner_of_my_first_sop).person)
    assert res, "policy with sharing_scope = 'Policy::ALL_USERS' wouldn't allow SysMO user to perform allowed action"
  end

  # 'private' policy
  def test_authorized_by_policy_private_policy_anonymous_user
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), sops(:my_first_sop), 'download', nil, nil)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow not logged in users to perform allowed action"
  end

  def test_authorized_by_policy_private_policy_registered_user
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), sops(:my_first_sop), 'download', users(:registered_user_with_no_projects), users(:registered_user_with_no_projects).person)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow registered user to perform allowed action"
  end

  def test_authorized_by_policy_private_policy_sysmo_user
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), sops(:my_first_sop), 'download', users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow SysMO user to perform allowed action"
  end

  def test_authorized_by_policy_private_policy_sysmo_user_versioned
    res = temp_authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), sops(:my_first_sop).latest_version, 'download', users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !res, "policy with sharing_scope = 'Policy::PRIVATE' would allow SysMO user to perform allowed action"
  end

  # ****************************************************************************
  # This section is dedicated to test the main method of the module:
  #     is_authorized?(action_name, thing_type, thing, user=nil)
  # ****************************************************************************

  # testing combinations of types of input parameters
  def test_is_authorized_for_model
    res = Seek::Permissions::Authorization.is_authorized?('view', models(:teusink), users(:model_owner))
    assert res, 'model_owner should be able to view his own model'
  end

  def test_is_not_authorized_for_model
    res = Seek::Permissions::Authorization.is_authorized?('view', models(:teusink), users(:quentin))
    assert res, "Quentin should not be able to view the model_owner's model"
  end

  # testing that asset owners can delete (plus verifying different options fur submitting the 'thing' and the 'user')

  def test_is_authorized_owner_who_is_not_policy_admin_can_delete
    res = Seek::Permissions::Authorization.is_authorized?('delete', sops(:sop_with_complex_permissions), users(:owner_of_my_first_sop))
    assert res, "owner of asset who isn't its policy admin couldn't delete the asset"
  end

  # testing favourite groups

  # someone with individual permission and in favourite group (more access than in individual permission) - permission in favourite group should never be used in such case
  def test_fav_group_permissions_dont_get_used_if_individual_permissions_exist
    temp = sops(:sop_with_download_for_all_sysmo_users_policy).policy.use_allowlist
    assert !temp, "policy for test SOP shouldn't use allowlist"

    temp = sops(:sop_with_download_for_all_sysmo_users_policy).policy.use_denylist
    assert !temp, "policy for test SOP shouldn't use denylist"

    # download is allowed for all sysmo users..
    temp = temp_authorized_by_policy?(sops(:sop_with_download_for_all_sysmo_users_policy).policy, sops(:sop_with_download_for_all_sysmo_users_policy), 'download',
                                      users(:sysmo_user_who_wants_to_access_different_things), users(:sysmo_user_who_wants_to_access_different_things).person)
    assert temp, "policy of the test SOP should have allowed 'download' of that asset"

    # ..but editing is not allowed
    temp = temp_authorized_by_policy?(sops(:sop_with_download_for_all_sysmo_users_policy).policy, sops(:sop_with_download_for_all_sysmo_users_policy), 'edit',
                                      users(:sysmo_user_who_wants_to_access_different_things), users(:sysmo_user_who_wants_to_access_different_things).person)
    assert !temp, "policy of the test SOP shouldn't have allowed 'edit' of that asset"

    # verify that permissions for the user exist, but don't give enough access rights..
    permissions = temp_get_person_permissions(users(:sysmo_user_who_wants_to_access_different_things).person, sops(:sop_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 1, "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type == Policy::VISIBLE, 'expected that the permission would give the test user viewing access to the test SOP, but no access for editing'

    # ..check that sharing with favourite group gives more access to this person..
    permissions = temp_get_person_access_rights_from_favourite_group_permissions(users(:sysmo_user_who_wants_to_access_different_things).person, sops(:sop_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 1, "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type == Policy::EDITING, 'expected that the permission would give the test user access to the test SOP for editing'

    # ..and now verify that permissions from favourite groups won't get used, because individual permissions have precedence
    res = Seek::Permissions::Authorization.is_authorized?('edit', sops(:sop_with_download_for_all_sysmo_users_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert !res, "test user should not have been allowed to 'edit' the SOP - individual permission should have denied the action"

    res = Seek::Permissions::Authorization.is_authorized?('view', sops(:sop_with_download_for_all_sysmo_users_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'view' the SOP - this is what individual permissions only allow"
  end

  # someone with no individual permissions - hence the actual permission from being a member in a favourite group is used
  def test_fav_groups_permissions
    temp = sops(:sop_with_download_for_all_sysmo_users_policy).policy.use_allowlist
    assert !temp, "policy for test SOP shouldn't use allowlist"

    temp = sops(:sop_with_download_for_all_sysmo_users_policy).policy.use_denylist
    assert !temp, "policy for test SOP shouldn't use denylist"

    # editing is not allowed by policy (only download is)
    temp = temp_authorized_by_policy?(sops(:sop_with_download_for_all_sysmo_users_policy).policy, sops(:sop_with_download_for_all_sysmo_users_policy), 'edit',
                                      users(:owner_of_my_first_sop), users(:owner_of_my_first_sop).person)
    assert !temp, "policy of the test SOP shouldn't have allowed 'edit' of that asset"

    # verify that no individual permissions for the user exist..
    permissions = temp_get_person_permissions(users(:owner_of_my_first_sop).person, sops(:sop_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 0, "expected to have no permission in that policy for the test person, not #{permissions.length}"

    # ..check that sharing with favourite group gives some access to this person..
    permissions = temp_get_person_access_rights_from_favourite_group_permissions(users(:owner_of_my_first_sop).person, sops(:sop_with_download_for_all_sysmo_users_policy).policy)
    assert permissions.length == 1, "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert permissions[0].access_type == Policy::EDITING, 'expected that the permission would give the test user access to the test SOP for editing'

    # ..and now verify that permissions from favourite groups are actually used
    res = Seek::Permissions::Authorization.is_authorized?('edit', sops(:sop_with_download_for_all_sysmo_users_policy), users(:owner_of_my_first_sop))
    assert res, "test user should have been allowed to 'edit' the SOP - because of favourite group membership and permissions"
  end

  # testing general policy settings

  def test_general_policy_settings_action_allowed
    # check that no permissions will be used..
    temp = sops(:sop_with_fully_public_policy).policy.use_allowlist
    assert !temp, "'use_allowlist' flag should be set to 'false' for this test"

    temp = sops(:sop_with_fully_public_policy).policy.use_denylist
    assert !temp, "'use_denylist' flag should be set to 'false' for this test"

    group_permissions = temp_get_group_permissions(sops(:sop_with_fully_public_policy).policy)
    assert group_permissions.empty?, 'there should be no group permissions for this policy'

    person_permissions = temp_get_person_permissions(users(:owner_of_my_first_sop).person, sops(:sop_with_fully_public_policy).policy)
    assert person_permissions.empty?, 'there should be no person permissions for this policy'

    # ..all flags are checked to 'false'; only policy settings will be used
    res = Seek::Permissions::Authorization.is_authorized?('edit', sops(:sop_with_fully_public_policy), users(:sysmo_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'edit' the SOP - it uses fully public policy"
  end

  def test_general_policy_settings_action_not_authorized
    # check that no permissions will be used..
    temp = sops(:sop_with_public_download_and_no_custom_sharing).policy.use_allowlist
    assert !temp, "'use_allowlist' flag should be set to 'false' for this test"

    temp = sops(:sop_with_public_download_and_no_custom_sharing).policy.use_denylist
    assert !temp, "'use_denylist' flag should be set to 'false' for this test"

    group_permissions = temp_get_group_permissions(sops(:sop_with_public_download_and_no_custom_sharing).policy)
    assert group_permissions.empty?, 'there should be no group permissions for this policy'

    person_permissions = temp_get_person_permissions(users(:owner_of_my_first_sop).person, sops(:sop_with_public_download_and_no_custom_sharing).policy)
    assert person_permissions.empty?, 'there should be no person permissions for this policy'

    # ..all flags are checked to 'false'; only policy settings will be used
    res = Seek::Permissions::Authorization.is_authorized?('edit', sops(:sop_with_public_download_and_no_custom_sharing), users(:sysmo_user_who_wants_to_access_different_things))
    assert !res, "test user shouldn't have been allowed to 'edit' the SOP - policy only allows downloading"

    res = Seek::Permissions::Authorization.is_authorized?('download', sops(:sop_with_public_download_and_no_custom_sharing), users(:sysmo_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'download' the SOP - policy allows downloading"
  end

  # testing group permissions

  # no specific permissions; action not allowed by policy; allowed by a group permission for 'WorkGroup';
  def test_group_permissions_will_allow_action
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_workgroups).policy.use_allowlist
    assert !temp, "'use_allowlist' flag should be set to 'false' for this test"

    temp = sops(:sop_for_test_with_workgroups).policy.use_denylist
    assert !temp, "'use_denylist' flag should be set to 'false' for this test"

    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(sops(:sop_for_test_with_workgroups).policy, sops(:sop_for_test_with_workgroups), 'download',
                                      users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !temp, "policy of the test SOP shouldn't have allowed 'download' of that asset"

    # verify that group permissions exist
    permissions = temp_get_group_permissions(sops(:sop_for_test_with_workgroups).policy)
    assert permissions.length == 1, "expected to have one permission for workgroups in that policy, not #{permissions.length}"
    assert permissions[0].contributor_type == 'WorkGroup', "expected to have permission for 'WorkGroup'"
    assert permissions[0].access_type == Policy::ACCESSIBLE, 'expected that the permission would give the test user download access to the test SOP'

    # verify that group permissions work and access is granted
    res = Seek::Permissions::Authorization.is_authorized?('download', sops(:sop_for_test_with_workgroups), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'download' the SOP - because of group permission"
  end

  # no specific permissions; action not allowed by policy; allowed by a group permission for 'Project'
  def test_group_permissions_shared_with_project
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_projects_institutions).policy.use_allowlist
    assert !temp, "'use_allowlist' flag should be set to 'false' for this test"

    temp = sops(:sop_for_test_with_projects_institutions).policy.use_denylist
    assert !temp, "'use_denylist' flag should be set to 'false' for this test"

    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(sops(:sop_for_test_with_projects_institutions).policy, sops(:sop_for_test_with_projects_institutions), 'edit',
                                      users(:owner_of_download_for_all_sysmo_users_policy), users(:owner_of_download_for_all_sysmo_users_policy).person)
    assert !temp, "policy of the test SOP shouldn't have allowed 'edit' of that asset"

    # verify that group permissions exist
    permissions = temp_get_group_permissions(sops(:sop_for_test_with_projects_institutions).policy)
    assert permissions.length == 2, "expected to have 2 permission for workgroups in that policy, not #{permissions.length}"
    if permissions[0].contributor_type == 'Project'
      perm = permissions[0]
    elsif permissions[1].contributor_type == 'Project'
      perm = permissions[1]
    else
      perm = nil
    end
    assert !perm.nil?, "couldn't find correct permission for the test"
    assert perm.access_type == Policy::EDITING, 'expected that the permission would give the test user edit access to the test SOP'

    # verify that group permissions work and access is granted
    res = Seek::Permissions::Authorization.is_authorized?('edit', sops(:sop_for_test_with_projects_institutions), users(:owner_of_download_for_all_sysmo_users_policy))
    assert res, "test user should have been allowed to 'download' the SOP - because of group permission: shared with test user's project"
  end

  # no specific permissions; action not allowed by policy; allowed by a group permission for 'Institution'
  def test_group_permissions_shared_with_institution
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_projects_institutions).policy.use_allowlist
    assert !temp, "'use_allowlist' flag should be set to 'false' for this test"

    temp = sops(:sop_for_test_with_projects_institutions).policy.use_denylist
    assert !temp, "'use_denylist' flag should be set to 'false' for this test"

    # verify that action wouldn't be allowed by policy
    temp = temp_authorized_by_policy?(sops(:sop_for_test_with_projects_institutions).policy, sops(:sop_for_test_with_projects_institutions), 'download',
                                      users(:owner_of_fully_public_policy), users(:owner_of_fully_public_policy).person)
    assert !temp, "policy of the test SOP shouldn't have allowed 'download' of that asset"

    # verify that group permissions exist
    permissions = temp_get_group_permissions(sops(:sop_for_test_with_projects_institutions).policy)
    assert permissions.length == 2, "expected to have 2 permission for workgroups in that policy, not #{permissions.length}"
    if permissions[0].contributor_type == 'Institution'
      perm = permissions[0]
    elsif permissions[1].contributor_type == 'Institution'
      perm = permissions[1]
    else
      perm = nil
    end
    assert !perm.nil?, "couldn't find correct permission for the test"
    assert perm.access_type == Policy::ACCESSIBLE, 'expected that the permission would give the test user download access to the test SOP'

    # verify that group permissions work and access is granted
    res = Seek::Permissions::Authorization.is_authorized?('download', sops(:sop_for_test_with_projects_institutions), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'download' the SOP - because of group permission: shared with test user's institution"
  end

  def test_downloadable_data_file
    data_file = data_files(:downloadable_data_file)
    res = Seek::Permissions::Authorization.is_authorized?('download', data_file, users(:aaron))
    assert res, 'should be downloadable by all'
    assert data_file.can_download?(users(:aaron))
    res = Seek::Permissions::Authorization.is_authorized?('edit', data_file, users(:aaron))
    assert !res, 'should not be editable'
    assert !data_file.can_edit?(users(:aaron))
  end

  def test_editable_data_file
    data_file = data_files(:editable_data_file)
    res = Seek::Permissions::Authorization.is_authorized?('download', data_file, users(:aaron))
    assert res, 'should be downloadable by all'
    assert data_file.can_download?(users(:aaron))
    res = Seek::Permissions::Authorization.is_authorized?('edit', data_file, users(:aaron))
    assert res, 'should be editable'
    assert data_file.can_edit?(users(:aaron))
  end

  def test_downloadable_sop
    sop = sops(:downloadable_sop)
    res = Seek::Permissions::Authorization.is_authorized?('download', sop, users(:aaron))
    assert res, 'Should be able to download'
    assert sop.can_download?(users(:aaron))

    assert sop.can_view? users(:aaron)

    res = Seek::Permissions::Authorization.is_authorized?('edit', sop, users(:aaron))
    assert !res, 'Should not be able to edit'
    assert !sop.can_edit?(users(:aaron))
  end

  def test_editable_sop
    sop = sops(:editable_sop)
    res = Seek::Permissions::Authorization.is_authorized?('download', sop, users(:aaron))
    assert res, 'Should be able to download'
    assert sop.can_download?(users(:aaron))

    assert sop.can_view?(users(:aaron))

    res = Seek::Permissions::Authorization.is_authorized?('edit', sop, users(:aaron))
    assert res, 'Should be able to edit'
    assert sop.can_edit?(users(:aaron))
  end

  def test_contributor_can_do_anything
    item = FactoryBot.create :sop, policy: FactoryBot.create(:private_policy)
    User.current_user = item.contributor
    actions.each { |a| assert item.can_perform? a }
    assert item.can_edit?
    assert item.can_view?
    assert item.can_download?
    assert item.can_delete?
    assert item.can_manage?
  end

  def test_private_item_does_not_allow_anything
    item = FactoryBot.create :sop, policy: FactoryBot.create(:private_policy)
    User.current_user = FactoryBot.create :user
    actions.each { |a| assert !item.can_perform?(a) }
    assert !item.can_edit?
    assert !item.can_view?
    assert !item.can_download?
    assert !item.can_delete?
    assert !item.can_manage?
  end

  def test_permissions
    User.current_user = FactoryBot.create :user
    access_levels = { Policy::MANAGING => actions,
                      Policy::NO_ACCESS => [],
                      Policy::VISIBLE => [:view],
                      Policy::ACCESSIBLE => [:view, :download],
                      Policy::EDITING => [:view, :download, :edit] }
    access_levels.each do |access, allowed|
      policy = FactoryBot.create :private_policy
      policy.permissions << FactoryBot.create(:permission, contributor: User.current_user.person, access_type: access, policy: policy)
      item = FactoryBot.create :sop, policy: policy
      actions.each { |action| assert_equal allowed.include?(action), item.can_perform?(action), "User should #{allowed.include?(action) ? nil : 'not '}be allowed to #{action}" }
      assert_equal item.can_view?, allowed.include?(:view)
      assert_equal item.can_edit?, allowed.include?(:edit)
      assert_equal item.can_download?, allowed.include?(:download)
      assert_equal item.can_delete?, allowed.include?(:delete)
      assert_equal item.can_manage?, allowed.include?(:manage)
    end
  end

  test 'creator should edit the asset, but can not manage' do
    item = FactoryBot.create :sop, policy: FactoryBot.create(:private_policy)
    person = FactoryBot.create :person
    FactoryBot.create :assets_creator, asset: item, creator: person

    User.current_user = person.user

    assert item.can_edit?
    assert item.can_view?
    assert item.can_download?
    assert !item.can_delete?
    assert !item.can_manage?
  end

  test "asset housekeeper can't manage the items inside their projects of members who have not left" do
    asset_manager = FactoryBot.create(:asset_housekeeper)
    work_group = asset_manager.work_groups.first
    project_member = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: work_group)])
    leaving_project_member = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership,
                                                                          time_left_at: 10.day.from_now,
                                                                          work_group: work_group)])
    datafile1 = FactoryBot.create(:data_file, contributor: project_member,
                                    projects: asset_manager.projects, policy: FactoryBot.create(:publicly_viewable_policy))
    datafile2 = FactoryBot.create(:data_file, contributor: project_member,
                                    projects: asset_manager.projects, policy: FactoryBot.create(:private_policy))
    datafile3 = FactoryBot.create(:data_file, contributor: leaving_project_member,
                                    projects: asset_manager.projects, policy: FactoryBot.create(:private_policy))

    refute Seek::Permissions::Authorization.authorized_by_role?('manage', datafile1, asset_manager)
    refute Seek::Permissions::Authorization.authorized_by_role?('manage', datafile2, asset_manager)
    refute Seek::Permissions::Authorization.authorized_by_role?('manage', datafile3, asset_manager)

    User.with_current_user asset_manager.user do
      assert !datafile1.can_manage?
      assert !datafile2.can_manage?
      assert !datafile3.can_manage?
    end
  end

  test 'asset housekeeper can manage the items inside their projects, even the entirely private items of former members' do
    asset_manager = FactoryBot.create(:asset_housekeeper)
    work_group = asset_manager.work_groups.first
    former_project_member = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, has_left: true, work_group: work_group)])
    datafile1 = nil
    datafile2 = nil
    disable_authorization_checks do
      datafile1 = FactoryBot.create(:data_file, contributor: former_project_member,
                                      projects: asset_manager.projects, policy: FactoryBot.create(:publicly_viewable_policy))
      datafile2 = FactoryBot.create(:data_file, contributor: former_project_member,
                                      projects: asset_manager.projects, policy: FactoryBot.create(:private_policy))
    end

    assert Seek::Permissions::Authorization.authorized_by_role?('manage', datafile1, asset_manager)
    assert Seek::Permissions::Authorization.authorized_by_role?('manage', datafile2, asset_manager)

    User.with_current_user asset_manager.user do
      assert datafile1.can_manage?
      assert datafile2.can_manage?
    end
  end

  test 'asset housekeeper can not manage the items outside their projects' do
    asset_manager = FactoryBot.create(:asset_housekeeper)
    datafile = FactoryBot.create(:data_file)
    assert (asset_manager.projects & datafile.projects).empty?

    refute Seek::Permissions::Authorization.authorized_by_role?('manage', datafile, asset_manager)

    User.with_current_user asset_manager.user do
      assert !datafile.can_manage?
    end
  end

  test 'asset housekeeper can not manage items for projects he is a member of but not manager of' do
    asset_manager = FactoryBot.create(:person_in_multiple_projects)
    project = asset_manager.projects.first
    other_project = asset_manager.projects.last
    asset_manager.is_asset_housekeeper = true, project
    datafile = FactoryBot.create(:data_file, projects: [other_project], contributor:FactoryBot.create(:person, project:other_project))
    refute (asset_manager.projects & datafile.projects).empty?

    refute Seek::Permissions::Authorization.authorized_by_role?('manage', datafile, asset_manager)

    User.with_current_user asset_manager.user do
      assert !datafile.can_manage?
    end
  end

  test 'asset housekeeper can manage jerm harvested items' do
    asset_manager = FactoryBot.create(:asset_housekeeper)
    datafile1 = FactoryBot.create(:jerm_data_file, projects: asset_manager.projects, policy: FactoryBot.create(:publicly_viewable_policy))

    assert Seek::Permissions::Authorization.authorized_by_role?('manage', datafile1, asset_manager)

    User.with_current_user asset_manager.user do
      assert datafile1.can_manage?
    end
  end

  test 'gatekeeper should not be able to manage the item' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    datafile = FactoryBot.create(:data_file, projects: gatekeeper.projects, policy: FactoryBot.create(:all_sysmo_viewable_policy), contributor:FactoryBot.create(:person,project:gatekeeper.projects.first))

    User.with_current_user gatekeeper.user do
      assert !datafile.can_manage?

      assert gatekeeper.is_asset_gatekeeper?(gatekeeper.projects.first)
      refute Seek::Permissions::Authorization.authorized_by_role?('publish', datafile, gatekeeper)
      refute Seek::Permissions::Authorization.authorized_by_role?('manage', datafile, gatekeeper)
    end
  end

  test 'should handle different types of contributor of resource (Person, User)' do
    asset_manager = FactoryBot.create(:asset_housekeeper)
    work_group = asset_manager.work_groups.first
    former_project_member = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, has_left: true, work_group: work_group)])

    policy = FactoryBot.create(:private_policy)
    policy2 = FactoryBot.create(:private_policy)
    permission = FactoryBot.create(:permission, contributor: former_project_member, access_type: 1)
    permission2 = FactoryBot.create(:permission, contributor: former_project_member, access_type: 1)
    policy.permissions = [permission]
    policy2.permissions = [permission2]

    # resources are not entirely private
    datafile = nil
    investigation = nil
    disable_authorization_checks do
      datafile = FactoryBot.create(:data_file, contributor: former_project_member, projects: asset_manager.projects, policy: policy)
      investigation = FactoryBot.create(:investigation, contributor: former_project_member, projects: asset_manager.projects, policy: policy)
    end

    User.with_current_user asset_manager.user do
      assert datafile.can_manage?
      assert investigation.can_manage?
    end
  end

  test 'unauthorized_change_to_autosave?' do
    df = FactoryBot.create(:data_file)
    assert_equal Policy::NO_ACCESS, df.policy.access_type
    df.policy.access_type = Policy::ACCESSIBLE
    assert !df.save
    assert !df.errors.empty?
    df.reload
    assert_equal Policy::NO_ACCESS, df.policy.access_type

    disable_authorization_checks do
      df.policy.access_type = Policy::NO_ACCESS
      assert df.save
      assert df.errors.empty?
      df.reload
      assert_equal Policy::NO_ACCESS, df.policy.access_type
    end
  end

  test 'can not delete for the asset which doi is minted' do
    User.current_user = FactoryBot.create :user
    df = FactoryBot.create :data_file, contributor: User.current_user.person
    assert df.can_delete?(User.current_user)

    version = df.latest_version
    version.doi = 'test_doi'
    disable_authorization_checks { version.save }

    assert !df.reload.can_delete?(User.current_user)
  end

  test 'old all registered users sharing policy honoured' do
    df = FactoryBot.create(:data_file,policy:FactoryBot.create(:policy,sharing_scope:Policy::ALL_USERS,access_type:Policy::ACCESSIBLE))
    user = FactoryBot.create(:person).user

    refute Seek::Permissions::Authorization.is_authorized?("edit",df,user)
    assert Seek::Permissions::Authorization.is_authorized?("download",df,user)
    assert Seek::Permissions::Authorization.is_authorized?("view",df,user)
    assert_equal true, Seek::Permissions::Authorization.is_authorized?("view",df,user)

    refute Seek::Permissions::Authorization.is_authorized?("edit",df,nil)
    refute Seek::Permissions::Authorization.is_authorized?("download",df,nil)
    refute Seek::Permissions::Authorization.is_authorized?("view",df,nil)
    assert_equal false, Seek::Permissions::Authorization.is_authorized?("view",df,nil)
  end

  test 'all users scope overrides more restrictive permissions' do
    person = FactoryBot.create(:person)

    user = person.user

    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy, permissions: [
        FactoryBot.create(:permission, contributor: person, access_type: Policy::NO_ACCESS)
    ]))
    assert sop.can_view?(nil)
    assert sop.can_download?(nil)
    assert sop.can_view?(user)
    assert sop.can_download?(user)

    person2 = FactoryBot.create(:person)
    user2 = person2.user

    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:publicly_viewable_policy, permissions: [
        FactoryBot.create(:permission, contributor: person, access_type: Policy::NO_ACCESS),
        FactoryBot.create(:permission, contributor: person2, access_type: Policy::ACCESSIBLE)
    ]))

    assert sop.can_view?(nil)
    refute sop.can_download?(nil)
    assert sop.can_view?(user)
    refute sop.can_download?(user)

    assert sop.can_view?(user2)
    assert sop.can_download?(user2)
  end

  test 'permissions can only add more privileges, not remove them' do
    person = FactoryBot.create(:person)
    user = person.user
    public_item = FactoryBot.create(:sop, policy: FactoryBot.create(:all_sysmo_viewable_policy))
    private_item = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy))

    User.with_current_user(user) do
      assert public_item.can_view?
      refute public_item.can_edit?
    end

    User.with_current_user user do
      refute private_item.can_view?
      refute private_item.can_edit?
    end

    # Add 'edit' permission to private item
    User.with_current_user(private_item.contributor) do
      FactoryBot.create(:permission, contributor: person, access_type: Policy::EDITING, policy: private_item.policy)
      private_item.reload
    end
    # Can edit?
    User.with_current_user user do
      assert private_item.can_view?
      assert private_item.can_edit?
    end

    # Add 'no access' permission to public item
    User.with_current_user(public_item.contributor) do
      FactoryBot.create(:permission, contributor: person, access_type: Policy::NO_ACCESS, policy: public_item.policy)
      public_item.reload
    end
    # Can still view?
    User.with_current_user user do
      assert public_item.can_view?
      refute public_item.can_edit?
    end
  end

  test 'user with no project can still view ALL_USERS-scoped resources' do
    public_item = FactoryBot.create(:sop, policy: FactoryBot.create(:all_sysmo_viewable_policy))
    person = FactoryBot.create(:person_not_in_project)

    User.with_current_user(nil) do
      refute public_item.can_view?
    end

    User.with_current_user(person.user) do
      assert public_item.can_view?
    end
  end

  test 'programme permissions' do
    programme = FactoryBot.create(:programme)

    project1 = FactoryBot.create(:project, programme: programme)
    project2 = FactoryBot.create(:project, programme: programme)
    project3 = FactoryBot.create(:project)

    person1 = FactoryBot.create(:person, project: project1)
    person2 = FactoryBot.create(:person, project: project2)
    person3 = FactoryBot.create(:person, project: project3)

    sop = FactoryBot.create(:sop, contributor: person1, policy: FactoryBot.create(:private_policy))
    sop.reload

    assert sop.can_view?(person1.user)
    refute sop.can_view?(person2.user)
    refute sop.can_view?(person3.user)

    sop.policy.permissions.create!(contributor: programme, access_type: Policy::ACCESSIBLE)
    sop = Sop.find(sop.id) # HAve to do this to clear authorization "cache"

    assert sop.can_view?(person1.user)
    assert sop.can_view?(person2.user)
    refute sop.can_view?(person3.user)

    # All other users
    ([nil] + User.includes(:person).all.reject { |u| u.person.nil? || u.person.programmes.include?(programme) }).each do |user|
      refute sop.can_view?(user)
    end
  end

  test 'programme permissions precedence' do
    programme = FactoryBot.create(:programme)

    project1 = FactoryBot.create(:project, programme: programme)
    project2 = FactoryBot.create(:project, programme: programme)
    project3 = FactoryBot.create(:project)

    person1 = FactoryBot.create(:person, project: project1)
    person2 = FactoryBot.create(:person, project: project2)
    person3 = FactoryBot.create(:person, project: project3)

    sop = FactoryBot.create(:sop, contributor: person1, policy: FactoryBot.create(:private_policy))
    sop.policy.permissions.create!(contributor: programme, access_type: Policy::VISIBLE)
    sop.reload

    assert sop.can_view?(person1.user)
    assert sop.can_view?(person2.user)
    refute sop.can_view?(person3.user)
    assert sop.can_download?(person1.user)
    refute sop.can_download?(person2.user)
    refute sop.can_download?(person3.user)

    sop.policy.permissions.create!(contributor: project2, access_type: Policy::ACCESSIBLE)
    sop = Sop.find(sop.id) # Have to do this to clear authorization "cache"

    assert sop.can_view?(person1.user)
    assert sop.can_view?(person2.user)
    refute sop.can_view?(person3.user)
    assert sop.can_download?(person1.user)
    assert sop.can_download?(person2.user)
    refute sop.can_download?(person3.user)
  end


  test 'cannot add content to former project' do
    work_group = FactoryBot.create(:work_group)
    former_project_member = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, has_left: true, work_group: work_group)])
    datafile = FactoryBot.build(:data_file, contributor: former_project_member,
                             projects: [work_group.project], policy: FactoryBot.create(:publicly_viewable_policy))

    refute datafile.save
    assert datafile.errors[:base].any? { |e| e.include?('active member') }
  end



  private 

  def actions
    [:view, :edit, :download, :delete, :manage]
  end

  # To save me re-writing lots of tests. Code copied from authorization.rb
  # Mimics how authorized_by_policy method used to work, but with my changes.
  def temp_authorized_by_policy?(_policy, thing, action, user, _not_used_2)
    Seek::Permissions::Authorization.send(:authorized_by_policy?, action, thing,user)
  end

  def temp_get_group_permissions(policy)
    policy.permissions.select { |p| %w(WorkGroup Project Institution).include?(p.contributor_type) }
  end

  def temp_get_person_permissions(person, policy)
    policy.permissions.select { |p| p.contributor == person }
  end

  def temp_get_person_access_rights_from_favourite_group_permissions(person, policy)
    favourite_group_ids = policy.permissions.select { |p| p.contributor_type == 'FavouriteGroup' }.collect(&:contributor_id)
    # Use favourite_group_membership in place of permission. It has access_type so duck typing will save us.
    person.favourite_group_memberships.select { |x| favourite_group_ids.include?(x.favourite_group_id) }
  end

end
