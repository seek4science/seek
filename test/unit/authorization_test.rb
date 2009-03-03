require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :users, :people, :assets, :sops, :policies, :favourite_groups, :favourite_group_memberships, :projects, :institutions, :work_groups, :group_memberships
  
  # ************************************************************************
  # this section tests individual helper methods within Authorization module
  # ************************************************************************
  
  # testing: find_thing(thing_type, thing_id)
  
  def test_find_thing_helper_try_to_find_resource
    found = Authorization.find_thing(sops(:my_first_sop).class.name, sops(:my_first_sop).id)
    
    assert found.class.name == "Asset", "returned instance is not of class 'Asset'"
    assert found.id == sops(:my_first_sop).asset.id, "id of found Asset is not correct"
  end
  
  def test_find_thing_helper_try_to_find_not_existing_resource
    found = Authorization.find_thing(sops(:my_first_sop).class.name, '0')
    
    assert_nil found, "return value should have been 'nil'"
  end
  
  def test_find_thing_helper_try_to_find_asset
    found = Authorization.find_thing(assets(:asset_of_my_first_sop).class.name, assets(:asset_of_my_first_sop).id)
    
    assert found.class.name == "Asset", "returned instance is not of class 'Asset'"
    assert found.id == assets(:asset_of_my_first_sop).id, "id of found Asset is not correct"
  end
  
  def test_find_thing_helper_try_to_find_not_existing_asset
    found = Authorization.find_thing(assets(:asset_of_my_first_sop).class.name, '0')
    
    assert_nil found, "return value should have been 'nil'"
  end
  
  def test_find_thing_helper_try_to_find_thing_with_illegal_type
    found = Authorization.find_thing("illegal_thing_type_that_will_never_be_used", 123)
    
    assert_nil found, "return value should have been 'nil'"
  end
  
  
  
  # testing: get_policy(policy_id, thing_asset)
  # TODO
  
  
  
  # testing: get_default_policy(thing_asset)
  # TODO
  
  
  
  # testing: is_owner?(user_id, thing_asset)
  
  # checks real owner ('contributor' of both SOP and corresponding asset)
  def test_is_owner_real_owner
    res = Authorization.is_owner?(users(:owner_of_my_first_sop).id, assets(:asset_of_my_first_sop))
    
    assert res, "real owner of the asset wasn't considered as such"
  end
  
  # checks not an owner
  def test_is_owner_random_user
    res = Authorization.is_owner?(users(:owner_of_fully_public_policy).id, assets(:asset_of_my_first_sop))
    
    assert (!res), "random user was thought to be an owner of the asset"
  end
  
  # checks that last editor of SOP is not treated as owner (owner is 'contributor' of the asset, but last editor - 'contributor' in SOP)
  def test_is_owner_last_editor_isnt_owner
    res = Authorization.is_owner?(users(:owner_of_a_sop_with_complex_permissions).id, assets(:asset_of_a_sop_with_complex_permissions))
    assert res, "assertion 1/2 in this test case: real owner of the asset wasn't considered as such"
    
    res = Authorization.is_owner?(users(:owner_of_my_first_sop).id, assets(:asset_of_a_sop_with_complex_permissions))
    assert (!res), "assertion 2/2 in this test case: last editor of the asset was considered as owner"
  end
  
  # checks that owner of asset's policy (but not the asset!) wouldn't be treated as asset owner
  def test_is_owner_user_is_policy_owner_not_asset_owner
    res = Authorization.is_owner?(users(:owner_of_complex_permissions_policy).id, assets(:asset_of_a_sop_with_complex_permissions))
  
    assert (!res), "asset's policy owner was considered to be owner of the asset itself"
  end
  
  
  
  # testing: is_policy_admin?(policy, user_id)
  
  def test_is_policy_admin_no_policy_supplied
    res = Authorization.is_policy_admin?(nil, users(:owner_of_my_first_sop).id)
    
    assert (!res), "random user was considered to be an admin of 'nil' policy"
  end
  
  def test_is_policy_admin_no_user_id_supplied
    res = Authorization.is_policy_admin?(policies(:private_policy_for_asset_of_my_first_sop), nil)
    
    assert (!res), "'nil' user was considered to be an admin of an existing policy"
  end
  
  def test_is_policy_admin_true
    res = Authorization.is_policy_admin?(policies(:private_policy_for_asset_of_my_first_sop), users(:owner_of_my_first_sop).id)
    
    assert res, "owner of a policy wasn't recognized as if it was the case"
  end
  
  def test_is_policy_admin_false
    res = Authorization.is_policy_admin?(policies(:fully_public_policy), users(:owner_of_my_first_sop).id)
    
    assert (!res), "random existing user was recognized as an admin of a random existing policy"
  end
  
  
  
  # testing: get_person_access_rights_in_favourite_group(person_id, favourite_group)
  
  # supplying favourite group ID as a second parameter
  def test_get_person_access_rights_in_favourite_group__parameter_option1_should_yield_viewing
    res = Authorization.get_person_access_rights_in_favourite_group(people(:person_for_owner_of_fully_public_policy).id, favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).id)
    
    assert res == Policy::VIEWING, "wrong access type returned for existing membership of a person in a favourite group"
  end
  
  # supplying favourite group as an array of user_id (user = owner of the group) and group name (favourite group names are unique in a per-user manner)
  def test_get_person_access_rights_in_favourite_group__parameter_option2_should_yield_viewing
    res = Authorization.get_person_access_rights_in_favourite_group(people(:person_for_owner_of_fully_public_policy).id, [users(:owner_of_a_sop_with_complex_permissions).id, favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).name])
    
    assert res == Policy::VIEWING, "wrong access type returned for existing membership of a person in a favourite group"
  end
  
  # supplying favourite group ID as a second parameter
  def test_get_person_access_rights_in_favourite_group__parameter_option1_should_yield_nil
    res = Authorization.get_person_access_rights_in_favourite_group(people(:random_userless_person).id, favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).id)
    
    assert_nil res, "test person is not in the favourite group - method should have returned NIL"
  end
  
  # supplying favourite group as an array of user_id (user = owner of the group) and group name (favourite group names are unique in a per-user manner)
  def test_get_person_access_rights_in_favourite_group__parameter_option2_should_yield_nil
    res = Authorization.get_person_access_rights_in_favourite_group(people(:random_userless_person).id, [users(:owner_of_a_sop_with_complex_permissions).id, favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).name])
    
    assert_nil res, "test person is not in the favourite group - method should have returned NIL"
  end
  
  
  
  # testing: is_person_in_whitelist?(person_id, whitelist_owner_user_id)
  
  def test_is_person_in_whitelist__should_yield_true
    res = Authorization.is_person_in_whitelist?(people(:person_for_owner_of_fully_public_policy).id, users(:owner_of_a_sop_with_complex_permissions).id)
    
    assert res, "test person should have been identified as being in the whitelist of test user"
  end
  
  def test_is_person_in_whitelist__should_yield_false
    res = Authorization.is_person_in_whitelist?(people(:random_userless_person).id, users(:owner_of_a_sop_with_complex_permissions).id)
    
    assert (!res), "test person should have not been identified as being in the whitelist of test user"
  end
  
  
  
  # testing: is_person_in_blacklist?(person_id, blacklist_owner_user_id)
  
  def test_is_person_in_blacklist__should_yield_true
    res = Authorization.is_person_in_blacklist?(people(:person_for_owner_of_my_first_sop).id, users(:owner_of_a_sop_with_complex_permissions).id)
    
    assert res, "test person should have been identified as being in the blacklist of test user"
  end
  
  def test_is_person_in_blacklist__should_yield_false
    res = Authorization.is_person_in_blacklist?(people(:random_userless_person).id, users(:owner_of_a_sop_with_complex_permissions).id)
    
    assert (!res), "test person should have not been identified as being in the blacklist of test user"
  end
  
  
  
  # testing: is_member?(person_id, group_type, group_id)
  
  # FavouriteGroup
  def test_is_member_in_fav_group_true
    res = Authorization.is_member?(people(:person_for_owner_of_fully_public_policy).id,
                                   favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).class.name,
                                   favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).id)
    
    assert res, "test person should have been identified as a member of test favourite group"
  end
  
  # FavouriteGroup
  def test_is_member_in_fav_group_false
    res = Authorization.is_member?(people(:random_userless_person).id,
                                   favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).class.name,
                                   favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions).id)
    
    assert (!res), "test person should NOT have been identified as a member of test favourite group"
  end
  
  # Project
  def test_is_member_in_project_true
    res = Authorization.is_member?(people(:person_for_owner_of_my_first_sop).id,
                                   projects(:myexperiment_project).class.name,
                                   projects(:myexperiment_project).id)
    
    assert res, "test person should have been identified as a project member"
  end
  
  # Project
  def test_is_member_in_project_false
    res = Authorization.is_member?(people(:random_userless_person).id,
                                   projects(:myexperiment_project).class.name,
                                   projects(:myexperiment_project).id)
    
    assert (!res), "test person should NOT have been identified as a project member"
  end
  
  # Institution
  def test_is_member_in_institution_true
    res = Authorization.is_member?(people(:person_for_owner_of_fully_public_policy).id,
                                   institutions(:ebi_inst).class.name,
                                   institutions(:ebi_inst).id)
    
    assert res, "test person should have been identified as an institution member"
  end
  
  # Institution
  def test_is_member_in_institution_false
    res = Authorization.is_member?(people(:random_userless_person).id,
                                   institutions(:ebi_inst).class.name,
                                   institutions(:ebi_inst).id)
    
    assert (!res), "test person should NOT have been identified as an institution member"
  end
  
  # WorkGroup
  def test_is_member_in_workgroup_true
    res = Authorization.is_member?(people(:random_userless_person).id,
                                   work_groups(:sysmo_at_manchester_uni_workgroup).class.name,
                                   work_groups(:sysmo_at_manchester_uni_workgroup).id)
    
    assert res, "test person should have been identified as a workgroup member"
  end
  
  # WorkGroup
  def test_is_member_in_workgroup_false
    res = Authorization.is_member?(people(:person_for_owner_of_fully_public_policy).id,
                                   work_groups(:sysmo_at_manchester_uni_workgroup).class.name,
                                   work_groups(:sysmo_at_manchester_uni_workgroup).id)
    
    assert (!res), "test person should NOT have been identified as a workgroup member"
  end
  
  # WorkGroup
  def test_is_member_in_project_when_member_in_workgroup
    res = Authorization.is_member?(people(:random_userless_person).id,
                                   projects(:sysmo_project).class.name,
                                   projects(:sysmo_project).id)
    
    assert res, "workgroup member should have been identified as a member of project that is part of this workgroup"
  end
  
  # WorkGroup
  def test_is_member_in_institution_when_member_in_workgroup
    res = Authorization.is_member?(people(:random_userless_person).id,
                                   institutions(:manchester_uni_inst).class.name,
                                   institutions(:manchester_uni_inst).id)
    
    assert res, "workgroup member should have been identified as a member of institution that is part of this workgroup"
  end
  
  # member of any SysMO projects at all? (e.g. a "SysMO user": person who is associated with at least one project / institution ('workgroup'), not just a registered user)
  def test_is_member_associated_with_any_projects_true
    res = Authorization.is_member?(people(:random_userless_person).id, nil, nil)
    
    assert res, "person associated with some SysMO projects was thought not to be associated with any"
  end
  
  # member of any SysMO projects at all?
  def test_is_member_associated_with_any_projects_false
    res = Authorization.is_member?(people(:person_not_associated_with_any_projects).id, nil, nil)
    
    assert (!res), "person not associated with any SysMO projects was thought to be a member of some"
  end
  
  
  
  # testing: access_type_allows_action?(action, access_type)
  
  def test_access_type_allows_action_no_access
    assert !Authorization.access_type_allows_action?("view", Policy::NO_ACCESS), "'view' action should NOT have been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Authorization.access_type_allows_action?("download", Policy::NO_ACCESS), "'download' action should NOT have been allowed with access_type set to 'Policy::NO_ACCESS'"
    assert !Authorization.access_type_allows_action?("edit", Policy::NO_ACCESS), "'edit' action should have NOT been allowed with access_type set to 'Policy::NO_ACCESS'"
  end
  
  def test_access_type_allows_action_viewing_only
    assert Authorization.access_type_allows_action?("view", Policy::VIEWING), "'view' action should have been allowed with access_type set to 'Policy::VIEWING'"
    assert !Authorization.access_type_allows_action?("download", Policy::VIEWING), "'download' action should NOT have been allowed with access_type set to 'Policy::VIEWING'"
    assert !Authorization.access_type_allows_action?("edit", Policy::VIEWING), "'edit' action should have NOT been allowed with access_type set to 'Policy::VIEWING'"
  end
  
  def test_access_type_allows_action_viewing_and_downloading_only
    assert Authorization.access_type_allows_action?("view", Policy::DOWNLOADING), "'view' action should have been allowed with access_type set to 'Policy::DOWNLOADING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("download", Policy::DOWNLOADING), "'download' action should have been allowed with access_type set to 'Policy::DOWNLOADING'"
    assert !Authorization.access_type_allows_action?("edit", Policy::DOWNLOADING), "'edit' action should have NOT been allowed with access_type set to 'Policy::DOWNLOADING'"
  end
  
  def test_access_type_allows_action_editing
    assert Authorization.access_type_allows_action?("view", Policy::EDITING), "'view' action should have been allowed with access_type set to 'Policy::EDITING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("download", Policy::EDITING), "'download' action should have been allowed with access_type set to 'Policy::EDITING' (cascading permissions)"
    assert Authorization.access_type_allows_action?("edit", Policy::EDITING), "'edit' action should have been allowed with access_type set to 'Policy::EDITING'"
  end
  
  def test_access_type_allows_action_bad_action_not_allowed
    # this method *should not* be used to used to deal with 'destroy' actions, hence 'false' is expected value
    # (instead, 'destroy' is directly allowed if someone is found to be an owner of an Asset) 
    assert !Authorization.access_type_allows_action?("destroy", Policy::OWNER), "'destroy' action should NOT have been allowed - this is a too critical action to be handled within this method"
    
    # random action shouldn't be allowed
    assert !Authorization.access_type_allows_action?("test_action", Policy::OWNER), "unknown actions should be disabled, but was allowed in this test case"
  end
  
  
  
  # ****************************************************************************
  # this section tests integration of individual helpers in Authorization module
  # ****************************************************************************
  
  # testing: authorized_by_policy?(policy, thing_asset, action, user_id, user_person_id)
  
  # 'everyone' policy
  def test_authorized_by_policy_fully_public_policy_anonymous_user
    res = Authorization.authorized_by_policy?(policies(:fully_public_policy), assets(:asset_of_a_sop_with_fully_public_policy), "download", nil, nil)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow not logged in users to perform 'download' where it should allow even 'edit'"
  end
  
  def test_authorized_by_policy_fully_public_policy_registered_user
    res = Authorization.authorized_by_policy?(policies(:fully_public_policy), assets(:asset_of_a_sop_with_fully_public_policy), "download", users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow registered user to perform 'download' where it should allow even 'edit'"
  end
  
  def test_authorized_by_policy_fully_public_policy_sysmo_user
    res = Authorization.authorized_by_policy?(policies(:fully_public_policy), assets(:asset_of_a_sop_with_fully_public_policy), "download", users(:owner_of_my_first_sop).id, users(:owner_of_my_first_sop).person.id)
    assert res, "policy with sharing_scope = 'Policy::EVERYONE' wouldn't allow SysMO user to perform 'download' where it should allow even 'edit'"
  end
  
  # 'all registered users' policy
  def test_authorized_by_policy_all_registered_users_policy_anonymous_user
    res = Authorization.authorized_by_policy?(policies(:download_for_all_registered_users_policy), assets(:asset_of_a_sop_with_all_registered_users_policy), "download", nil, nil)
    assert (!res), "policy with sharing_scope = 'Policy::ALL_REGISTERED_USERS' would allow not logged in users to perform allowed action"
  end
  
  def test_authorized_by_policy_all_registered_users_policy_registered_user
    res = Authorization.authorized_by_policy?(policies(:download_for_all_registered_users_policy), assets(:asset_of_a_sop_with_all_registered_users_policy), "download", users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert res, "policy with sharing_scope = 'Policy::ALL_REGISTERED_USERS' wouldn't allow registered user to perform allowed action"
  end
  
  def test_authorized_by_policy_all_registered_users_policy_sysmo_user
    res = Authorization.authorized_by_policy?(policies(:download_for_all_registered_users_policy), assets(:asset_of_a_sop_with_all_registered_users_policy), "download", users(:owner_of_my_first_sop).id, users(:owner_of_my_first_sop).person.id)
    assert res, "policy with sharing_scope = 'Policy::ALL_REGISTERED_USERS' wouldn't allow SysMO user to perform allowed action"
  end
  
  # 'all SysMO users' policy
  def test_authorized_by_policy_all_sysmo_users_policy_anonymous_user
    res = Authorization.authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), assets(:asset_of_a_sop_with_all_sysmo_users_policy), "download", nil, nil)
    assert (!res), "policy with sharing_scope = 'Policy::ALL_SYSMO_USERS' would allow not logged in users to perform allowed action"
  end
  
  def test_authorized_by_policy_all_sysmo_users_policy_registered_user
    res = Authorization.authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), assets(:asset_of_a_sop_with_all_sysmo_users_policy), "download", users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert (!res), "policy with sharing_scope = 'Policy::ALL_SYSMO_USERS' would allow registered user to perform allowed action"
  end
  
  def test_authorized_by_policy_all_sysmo_users_policy_sysmo_user
    res = Authorization.authorized_by_policy?(policies(:editing_for_all_sysmo_users_policy), assets(:asset_of_a_sop_with_all_sysmo_users_policy), "download", users(:owner_of_my_first_sop).id, users(:owner_of_my_first_sop).person.id)
    assert res, "policy with sharing_scope = 'Policy::ALL_SYSMO_USERS' wouldn't allow SysMO user to perform allowed action"
  end
  
  # 'custom permissions only' policy
  def test_authorized_by_policy_custom_permissions_only_policy_anonymous_user
    res = Authorization.authorized_by_policy?(policies(:custom_permissions_only_policy), assets(:asset_of_a_sop_with_custom_permissions_policy), "download", nil, nil)
    assert (!res), "policy with sharing_scope = 'Policy::CUSTOM_PERMISSIONS_ONLY' would allow not logged in users to perform allowed action"
  end
  
  def test_authorized_by_policy_custom_permissions_only_policy_registered_user
    res = Authorization.authorized_by_policy?(policies(:custom_permissions_only_policy), assets(:asset_of_a_sop_with_custom_permissions_policy), "download", users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert (!res), "policy with sharing_scope = 'Policy::CUSTOM_PERMISSIONS_ONLY' would allow registered user to perform allowed action"
  end
  
  def test_authorized_by_policy_custom_permissions_only_policy_sysmo_user
    res = Authorization.authorized_by_policy?(policies(:custom_permissions_only_policy), assets(:asset_of_a_sop_with_custom_permissions_policy), "download", users(:owner_of_fully_public_policy).id, users(:owner_of_fully_public_policy).person.id)
    assert (!res), "policy with sharing_scope = 'Policy::CUSTOM_PERMISSIONS_ONLY' would allow SysMO user to perform allowed action"
  end
  
  # 'private' policy
  def test_authorized_by_policy_private_policy_anonymous_user
    res = Authorization.authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), assets(:asset_of_my_first_sop), "download", nil, nil)
    assert (!res), "policy with sharing_scope = 'Policy::PRIVATE' would allow not logged in users to perform allowed action"
  end
  
  def test_authorized_by_policy_private_policy_registered_user
    res = Authorization.authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), assets(:asset_of_my_first_sop), "download", users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert (!res), "policy with sharing_scope = 'Policy::PRIVATE' would allow registered user to perform allowed action"
  end
  
  def test_authorized_by_policy_private_policy_sysmo_user
    res = Authorization.authorized_by_policy?(policies(:private_policy_for_asset_of_my_first_sop), assets(:asset_of_my_first_sop), "download", users(:owner_of_fully_public_policy).id, users(:owner_of_fully_public_policy).person.id)
    assert (!res), "policy with sharing_scope = 'Policy::PRIVATE' would allow SysMO user to perform allowed action"
  end
  
  
  
  # ****************************************************************************
  # This section is dedicated to test the main method of the module:
  #     is_authorized?(action_name, thing_type, thing, user=nil)
  # ****************************************************************************
  
  # testing combinations of types of input parameters

  # various incorrect input parameters
  def test_is_authorized_invalid_action
    res = Authorization.is_authorized?("bad_action_name_that_will_never_be_used", nil, assets(:asset_of_my_first_sop), nil)
    assert (!res), "invalid action name was processed and permission to execute action granted"
  end
  
  def test_is_authorized_blank_thing_type_only_id_supplied
    res = Authorization.is_authorized?("view", nil, assets(:asset_of_my_first_sop).id, nil)
    assert (!res), "permission to execute action granted for a 'thing' with no type (only ID) provided"
  end
  
  def test_is_authorized_both_thing_parameters_blank
    res = Authorization.is_authorized?("view", nil, nil, nil)
    assert (!res), "permission to execute action granted for a 'thing' with no type / ID supplied"
  end
  
  
  # testing that asset owners can destroy (plus verifying different options fur submitting the 'thing' and the 'user')
  
  # checking that owner of the asset can destroy it
  # ('thing' supplied as type = 'nil' plus actual instance of the thing)
  def test_is_authorized_thing_as_instance
    res = Authorization.is_authorized?("destroy", nil, assets(:asset_of_my_first_sop), users(:owner_of_my_first_sop))
    assert res, "owner of the asset (supplied as instance) was denied destroying the asset"
  end
  
  # checking that owner of the asset can destroy it
  # ('thing' supplied as type plus ID of the thing)
  def test_is_authorized_thing_as_type_and_id
    res = Authorization.is_authorized?("destroy", assets(:asset_of_my_first_sop).class.name, assets(:asset_of_my_first_sop).id, users(:owner_of_my_first_sop))
    assert res, "owner of the asset (supplied as type + ID) was denied destroying the asset"
  end
  
  # checking that owner of the asset can destroy it
  # ('user' was supplied as an instance in all previous test cases, now checking that can submit an ID if necessary)
  def test_is_authorized_thing_as_type_and_id_user_as_id
    res = Authorization.is_authorized?("destroy", assets(:asset_of_my_first_sop).class.name, assets(:asset_of_my_first_sop).id, users(:owner_of_my_first_sop).id)
    assert res, "owner (supplied as ID) of the asset (supplied as type + ID) was denied destroying the asset"
  end
  
  
  # testing that policy admin can destroy, too (and that asset owner, who is not policy admin, also can destroy)
  def test_is_authorized_policy_admin_can_destroy
    res = Authorization.is_authorized?("destroy", nil, sops(:sop_with_complex_permissions), users(:owner_of_complex_permissions_policy))
    assert res, "owner of asset's policy couldn't destroy the asset"
  end
  
  def test_is_authorized_owner_who_is_not_policy_admin_can_destroy
    res = Authorization.is_authorized?("destroy", nil, sops(:sop_with_complex_permissions), users(:owner_of_a_sop_with_complex_permissions))
    assert res, "owner of asset who isn't its policy admin couldn't destroy the asset"
  end
  
end
