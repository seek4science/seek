require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  fixtures :all
  
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
  
  def test_find_thing_helper_for_model
    found = Authorization.find_thing(assets(:asset_for_model).class.name, assets(:asset_for_model).id)
    
    assert found.class.name == "Asset", "returned instance is not of class 'Asset'"
    assert found.id == assets(:asset_for_model).id, "id of found Asset is not correct"
  end

  
  # testing: is_owner?(user_id, thing_asset)
  
  # checks real owner ('contributor' of both SOP and corresponding asset)
  def test_is_owner_real_owner
    res = Authorization.is_owner?(users(:owner_of_my_first_sop).id, assets(:asset_of_my_first_sop))
    
    assert res, "real owner of the asset wasn't considered as such"
  end

  def test_is_owner_of_model
    res = Authorization.is_owner?(users(:model_owner).id, assets(:asset_for_model))

    assert res, "real owner of the asset wasn't considered as such"
  end

  def test_is_owner_of_datafile
    res = Authorization.is_owner?(users(:datafile_owner).id, assets(:asset_for_datafile))
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

  def test_authorized_for_model
    res = Authorization.authorized_by_policy?(policies(:policy_for_test_with_projects_institutions),assets(:asset_for_model),"view",users(:model_owner).id,people(:person_for_model_owner).id)
    assert res, "model_owner should be able to view his own model"
  end

  def test_not_authorized_for_model
    res = Authorization.authorized_by_policy?(policies(:policy_for_test_with_projects_institutions),assets(:asset_for_model),"download",users(:quentin).id,users(:quentin).person.id)
    assert !res, "Quentin should not be able to download that model"
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

  def test_is_authorized_for_model
    res = Authorization.is_authorized?("view", "Model", models(:teusink), users(:model_owner))
    assert res, "model_owner should be able to view his own model"
  end

  def test_is_not_authorized_for_model
    res = Authorization.is_authorized?("view", "Model", models(:teusink), users(:quentin))
    assert res, "Quentin should not be able to view his model_owner's model"
  end
  
  def test_is_authorized_both_thing_parameters_blank
    res = Authorization.is_authorized?("view", nil, nil, nil)
    assert (!res), "permission to execute action granted for a 'thing' with no type / ID supplied"
  end
  
  # completely random "thing" type --> should be authorised, as not known if there should be any checks on such "thing" type
  def test_thing_of_a_type_not_known_to_need_authorization_should_be_authorized
    res = Authorization.is_authorized?("manage", "TypeOfACleverThingThatWeDontCareAbout", 123, nil)
    assert res, "wasn't allowed to perform an action on a thing with a type that is not known to require authorization"
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
  
  # check that owner can't destroy an asset, when it was recently used
  # TODO implement this check after relevant feature implemented in the Authorization module
  
  # check that owner can't destroy an asset, when something is linked to it
  # TODO implement this check after relevant feature implemented in the Authorization module
  
  
  # testing that policy admin can destroy, too (and that asset owner, who is not policy admin, also can destroy)
  def test_is_authorized_policy_admin_can_destroy
    temp = Authorization.is_policy_admin?(sops(:sop_with_complex_permissions).asset.policy, users(:owner_of_complex_permissions_policy).id)
    assert temp, "test user should have been a policy admin"
    
    res = Authorization.is_authorized?("destroy", nil, sops(:sop_with_complex_permissions), users(:owner_of_complex_permissions_policy))
    assert res, "owner of asset's policy couldn't destroy the asset"
  end
  
  def test_is_authorized_owner_who_is_not_policy_admin_can_destroy
    temp = Authorization.is_owner?(users(:owner_of_a_sop_with_complex_permissions).id, sops(:sop_with_complex_permissions).asset)
    assert temp, "test user should have been the asset owner"
    
    temp = Authorization.is_policy_admin?(sops(:sop_with_complex_permissions).asset.policy, users(:owner_of_a_sop_with_complex_permissions).id)
    assert (!temp), "test user shouldn't have been a policy admin"
    
    res = Authorization.is_authorized?("destroy", nil, sops(:sop_with_complex_permissions), users(:owner_of_a_sop_with_complex_permissions))
    assert res, "owner of asset who isn't its policy admin couldn't destroy the asset"
  end
  
  # check that policy admin can't destroy an asset, when it was recently used
  # TODO implement this check after relevant feature implemented in the Authorization module
  
  # check that policy admin can't destroy an asset, when something is linked to it
  # TODO implement this check after relevant feature implemented in the Authorization module
  
  
  # testing whitelist / blacklist
  
  # policy.use_whitelist == true AND test person in the whitelist AND allowed action --> true
  def test_person_in_whitelist_and_use_whitelist_set_to_true
    temp = sops(:sop_with_custom_permissions_policy).asset.policy.use_whitelist
    assert temp, "use_whitelist should have been set to 'true'"
    
    temp = Authorization.is_person_in_whitelist?(users(:test_user_only_in_whitelist).person.id, sops(:sop_with_custom_permissions_policy).asset.contributor.id)
    assert temp, "test person should have been in the whitelist of the sop owner"
    
    res = Authorization.is_authorized?("download", nil, sops(:sop_with_custom_permissions_policy), users(:test_user_only_in_whitelist))
    assert res, "download should have been authorized for a a person in the whitelist - flag to use whitelist was set"
  end
  
  # policy.use_whitelist == true AND test person in the whitelist AND not authorized action --> false (currently "edit" requires more access rights than just being in the whitelist)
  def test_person_in_whitelist_and_use_whitelist_set_to_true_but_not_authorized_action
    temp = sops(:sop_with_custom_permissions_policy).asset.policy.use_whitelist
    assert temp, "use_whitelist should have been set to 'true'"
    
    temp = Authorization.is_person_in_whitelist?(users(:test_user_only_in_whitelist).person.id, sops(:sop_with_custom_permissions_policy).asset.contributor.id)
    assert temp, "test person should have been in the whitelist of the sop owner"
    
    temp = (Policy::EDITING > FavouriteGroup::WHITELIST_ACCESS_TYPE)
    assert temp, "editing is now authorized by whitelist access type"
    
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_custom_permissions_policy), users(:test_user_only_in_whitelist))
    assert (!res), "editing shouldn't have been authorized for a a person in the whitelist - flag to use whitelist was set"
  end
  
  
  # policy.use_whitelist == false AND test person in the whitelist --> false (e.g. permission for whitelist exists, but policy flag isn't set)
  def test_person_in_whitelist_and_allowed_action_but_use_whitelist_set_to_false
    temp = sops(:my_first_sop).asset.policy.use_whitelist
    assert (!temp), "use_whitelist should have been set to 'false'"
    
    temp = Authorization.is_person_in_whitelist?(users(:test_user_only_in_whitelist).person.id, sops(:my_first_sop).asset.contributor.id)
    assert temp, "test person should have been in the whitelist of the sop owner"
    
    res = Authorization.is_authorized?("download", nil, sops(:my_first_sop), users(:test_user_only_in_whitelist))
    assert (!res), "download shouldn't have been authorized for a a person in the whitelist - flag to use whitelist wasn't set"
  end
  
  # policy.use_whitelist == false AND test person not in the whitelist --> false
  def test_person_not_in_whitelist_and_allowed_action_and_use_whitelist_set_to_false
    temp = sops(:my_first_sop).asset.policy.use_whitelist
    assert (!temp), "use_whitelist should have been set to 'false'"
    
    temp = Authorization.is_person_in_whitelist?(users(:registered_user_with_no_projects).person.id, sops(:my_first_sop).asset.contributor.id)
    assert (!temp), "test person shouldn't have been in the whitelist of the sop owner"
    
    res = Authorization.is_authorized?("download", nil, sops(:my_first_sop), users(:registered_user_with_no_projects))
    assert (!res), "download shouldn't have been authorized for a a person not in the whitelist - especially when flag to use whitelist wasn't set"
  end
  
  # policy.use_blacklist == true AND test person in the blacklist --> false
  def test_person_in_blacklist_and_use_blacklist_set_to_true
    temp = sops(:sop_with_all_sysmo_users_policy).asset.policy.use_blacklist
    assert temp, "use_blacklist should have been set to 'true'"
    
    temp = Authorization.is_member?(people(:person_for_sysmo_user_in_blacklist).id, nil, nil)
    assert temp, "test person is associated with some SysMO projects, but was thought not to be associated with any"
    
    temp = Authorization.is_person_in_blacklist?(people(:person_for_sysmo_user_in_blacklist).id, sops(:sop_with_all_sysmo_users_policy).asset.contributor.id)
    assert temp, "test person should have been in the blacklist of the sop owner"
    
    # "view" is used instead of "show" because that's a precondition for Authorization.access_type_allows_action?() helper - it assumes that
    # Authorization.categorize_action() was called on the action before - and that yields "view" for "show" action
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_sysmo_users_policy).asset.policy, sops(:sop_with_all_sysmo_users_policy).asset, "view", 
                                               people(:person_for_sysmo_user_in_blacklist).user.id, people(:person_for_sysmo_user_in_blacklist).id)
    assert temp, "test user is SysMO user and should have been authorized by policy"
    
    res = Authorization.is_authorized?("show", nil, sops(:sop_with_all_sysmo_users_policy), people(:person_for_sysmo_user_in_blacklist).user.id)
    assert (!res), "test user is SysMO user, but is also in blacklist - should not have been authorized for viewing"
  end
  
  # policy.use_blacklist == true AND test person not in the blacklist --> true
  def test_person_not_in_blacklist_and_use_blacklist_set_to_true
    temp = sops(:sop_with_all_sysmo_users_policy).asset.policy.use_blacklist
    assert temp, "use_blacklist should have been set to 'true'"
    
    temp = Authorization.is_member?(people(:person_for_owner_of_my_first_sop).id, nil, nil)
    assert temp, "test person is associated with some SysMO projects, but was thought not to be associated with any"
    
    temp = Authorization.is_person_in_blacklist?(people(:person_for_owner_of_my_first_sop).id, sops(:sop_with_all_sysmo_users_policy).asset.contributor.id)
    assert (!temp), "test person shouldn't have been in the blacklist of the sop owner"
    
    res = Authorization.is_authorized?("show", nil, sops(:sop_with_all_sysmo_users_policy), people(:person_for_owner_of_my_first_sop).user.id)
    assert res, "test user is SysMO user and is not in blacklist - should have been authorized for viewing"
  end
  
  # policy.use_blacklist == false AND test person in the blacklist --> true
  def test_person_in_the_blacklist_but_use_blacklist_set_to_false
    temp = sops(:sop_with_complex_permissions).asset.policy.use_blacklist
    assert (!temp), "use_blacklist should have been set to 'false'"
    
    temp = Authorization.is_person_in_blacklist?(users(:owner_of_my_first_sop).person.id, sops(:sop_with_complex_permissions).asset.contributor.id)
    assert temp, "test person should have been in the blacklist of the sop owner"
    
    res = Authorization.is_authorized?("view", nil, sops(:sop_with_complex_permissions), users(:owner_of_my_first_sop))
    assert res, "view should have been authorized for a a person in the blacklist - flag to use blacklist wasn't set"
  end
  
  # policy.use_blacklist == false AND test person not in the blacklist --> true
  def test_person_not_in_the_blacklist_and_use_blacklist_set_to_false
    temp = sops(:sop_with_complex_permissions).asset.policy.use_blacklist
    assert (!temp), "use_blacklist should have been set to 'false'"
    
    temp = Authorization.is_person_in_blacklist?(users(:test_user_only_in_whitelist).person.id, sops(:sop_with_complex_permissions).asset.contributor.id)
    assert (!temp), "test person shouldn't have been in the blacklist of the sop owner"
    
    res = Authorization.is_authorized?("view", nil, sops(:sop_with_complex_permissions), users(:test_user_only_in_whitelist))
    assert res, "view should have been authorized for a a person not in the blacklist - especially when flag to use blacklist wasn't set"
  end
  
  # policy.use_whitelist == true AND policy.use_blacklist == true AND test person in both whitelist and blacklist --> false
  def test_person_in_both_whitelist_and_blacklist
    # this is mainly to test that blacklist takes precedence over the whitelist
    
    temp = sops(:sop_with_all_sysmo_users_policy).asset.policy.use_whitelist
    assert temp, "'use_whitelist' flag should have been set to 'true' for this test"
    
    temp = sops(:sop_with_all_sysmo_users_policy).asset.policy.use_blacklist
    assert temp, "'use_blacklist' flag should have been set to 'true' for this test"
    
    temp = Authorization.is_person_in_blacklist?(users(:sysmo_user_both_in_blacklist_and_whitelist).person.id, sops(:sop_with_all_sysmo_users_policy).asset.contributor.id)
    assert temp, "test person should have been in the blacklist of the sop owner"
    
    temp = Authorization.is_person_in_whitelist?(users(:sysmo_user_both_in_blacklist_and_whitelist).person.id, sops(:sop_with_all_sysmo_users_policy).asset.contributor.id)
    assert temp, "test person should have been in the whitelist of the sop owner"
    
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_sysmo_users_policy).asset.policy, sops(:sop_with_all_sysmo_users_policy).asset, "edit", 
                                               users(:sysmo_user_both_in_blacklist_and_whitelist).id, users(:sysmo_user_both_in_blacklist_and_whitelist).person.id)
    assert temp, "test user is SysMO user and should have been authorized by policy"
    
    res = Authorization.is_authorized?("view", nil, sops(:sop_with_all_sysmo_users_policy), users(:sysmo_user_both_in_blacklist_and_whitelist))
  end
  
  
  # testing individual user permissions
  
  # someone not in whitelist / blacklist; action not allowed by policy; individual permissions exists to allow it; "use_custom_sharing" flag set to 'false'
  def test_custom_permissions_when_use_custom_sharing_set_to_false_but_individual_permissions_exist
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.use_whitelist
    assert (!temp), "policy for test SOP shouldn't use whitelist"
    
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.use_blacklist
    assert (!temp), "policy for test SOP shouldn't use blacklist"
    
    temp = Authorization.authorized_by_policy?(sops(:sop_with_public_download_and_no_custom_sharing).asset.policy, sops(:sop_with_public_download_and_no_custom_sharing).asset, "edit", 
                                               users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'edit' of that asset"
    
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.use_custom_sharing
    assert (!temp), "'use_custom_sharing' flag should be set to 'false' for this test"
    
    # verify that permissions for the user exist..
    permissions = Authorization.get_person_permissions(users(:registered_user_with_no_projects).person.id, sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type == Policy::EDITING), "expected that the permission would give the test user editing access to the test SOP"
    
    # ..and that these won't get used, because "use_custom_sharing" flag is set to false
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_public_download_and_no_custom_sharing), users(:registered_user_with_no_projects))
    assert (!res), "test user should not have been allowed to 'edit' the SOP even having the individual permission - use_custom_sharing is set to false"
    
    # (download will be, however, allowed - by the policy)
    res = Authorization.is_authorized?("download", nil, sops(:sop_with_public_download_and_no_custom_sharing), users(:registered_user_with_no_projects))
    assert res, "test user should have been allowed to 'download' the SOP - this is a policy setting"
  end
  
  # policy not whitelist / blacklist; action not allowed by policy; individual permissions exists to allow it; "use_custom_sharing" flag set to 'true'
  def test_custom_permissions_when_use_custom_sharing_set_to_true_and_permissions_allow_action
    temp = sops(:sop_with_private_policy_and_custom_sharing).asset.policy.use_whitelist
    assert (!temp), "policy for test SOP shouldn't use whitelist"
    
    temp = sops(:sop_with_private_policy_and_custom_sharing).asset.policy.use_blacklist
    assert (!temp), "policy for test SOP shouldn't use blacklist"
    
    temp = Authorization.authorized_by_policy?(sops(:sop_with_private_policy_and_custom_sharing).asset.policy, sops(:sop_with_private_policy_and_custom_sharing).asset, "view", 
                                               users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'view' of that asset"
    
    temp = sops(:sop_with_private_policy_and_custom_sharing).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    res = Authorization.is_authorized?("download", nil, sops(:sop_with_private_policy_and_custom_sharing), users(:registered_user_with_no_projects))
    assert res, "test user should have been allowed to download because of the individual permission"
  end
  
  # someone not in whitelist / blacklist; action allowed by policy; individual permissions exists to deny it
  def test_custom_permissions_when_use_custom_sharing_set_to_true_and_permissions_deny_action
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_whitelist
    assert (!temp), "policy for test SOP shouldn't use whitelist"
    
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_blacklist
    assert (!temp), "policy for test SOP shouldn't use blacklist"
    
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_registered_users_policy).asset.policy, sops(:sop_with_all_registered_users_policy).asset, "download", 
                                               users(:sysmo_user_in_blacklist).id, users(:sysmo_user_in_blacklist).person.id)
    assert temp, "policy of the test SOP should have allowed 'download' of that asset"
    
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    res = Authorization.is_authorized?("view", nil, sops(:sop_with_all_registered_users_policy), users(:sysmo_user_in_blacklist))
    assert (!res), "test user should not have been allowed to 'view' the SOP because of the individual permission"
  end
  
  # check that no permissions are processed for policy with sharing_scope == Policy::PRIVATE
  def test_custom_permissions_when_use_custom_sharing_set_to_true_and_sharing_scope_set_to_private
    temp = sops(:my_first_sop).asset.policy.use_whitelist
    assert (!temp), "policy for test SOP shouldn't use whitelist"
    
    temp = sops(:my_first_sop).asset.policy.use_blacklist
    assert (!temp), "policy for test SOP shouldn't use blacklist"
    
    temp = Authorization.authorized_by_policy?(sops(:my_first_sop).asset.policy, sops(:my_first_sop).asset, "view", 
                                               users(:registered_user_with_no_projects).id, users(:registered_user_with_no_projects).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'view' of that asset"
    
    temp = sops(:my_first_sop).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    # verify that permissions for the user exist..
    permissions = Authorization.get_person_permissions(users(:registered_user_with_no_projects).person.id, sops(:my_first_sop).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type > Policy::NO_ACCESS), "expected that the permission would give the test user some access to the test SOP"
    
    # ..and that these won't get used, because "sharing_scope" is set to Policy::PRIVATE, even though "use_custom_sharing" flag is set to true
    res = Authorization.is_authorized?("view", nil, sops(:my_first_sop), users(:registered_user_with_no_projects))
    assert (!res), "test user should not have been allowed to 'view' the SOP even having the individual permission and use_custom_sharing is set to true - this should have been denied by sharing_scope == Policy::PRIVATE"
  end
  
  # check that if the user is in the blacklist/whitelist, individual permissions will be used appropriately
  # (i.e. that blacklist has precedence over individual permissions, but whitelist doesn't -- 
  #  therefore, if someone is in the whitelist, but that wouldn't authorize the action, further checks will be made)
  def test_blacklist_has_precedence_over_individual_permissions
    temp = sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.use_blacklist
    assert temp, "policy for test SOP should use blacklist"
    
    temp = sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.use_custom_sharing
    assert temp, "policy for test SOP should use custom sharing"
    
    # verify that test user is in the blacklist
    temp = Authorization.is_person_in_blacklist?(users(:registered_user_with_no_projects).person.id, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.contributor.id)
    assert temp, "test person should have been in the blacklist of the sop owner"
    
    # verify that test user has an individual permission, too
    # (this has to give more access than the general policy settings) 
    permissions = Authorization.get_person_permissions(users(:registered_user_with_no_projects).person.id, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type > sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.access_type), "expected that the permission would give the test user more access than general policy settings"
    
    # verify that individual permission will not be used, because blacklist has precedence
    res = Authorization.is_authorized?("download", nil, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing), users(:registered_user_with_no_projects))
    assert (!res), "test user shouldn't have been allowed to 'download' the SOP even having the individual permission and use_custom_sharing is set to true - blacklist membership should have had precedence"
    
    # in fact, even 'viewing' allowed by general policy settings shouldn't be allowed because of the blacklist
    res = Authorization.is_authorized?("view", nil, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing), users(:registered_user_with_no_projects))
    assert (!res), "test user shouldn't have been allowed to 'view' the SOP - blacklist membership should have denied this"
  end
  
  def test_whitelist_doesnt_have_precedence_over_individual_permissions
    temp = sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.use_whitelist
    assert temp, "policy for test SOP should use whitelist"
    
    temp = sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.use_custom_sharing
    assert temp, "policy for test SOP should use custom sharing"
    
    # verify that test user is in the whitelist
    temp = Authorization.is_person_in_whitelist?(users(:owner_of_custom_permissions_only_policy).person.id, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.contributor.id)
    assert temp, "test person should have been in the whitelist of the sop owner"
    
    # verify that test user has an individual permission, too
    # (this has to give more access than membership in the whitelist for this test case to make sense:
    #  whitelist has to allow at most to download, but the test individual permission - to edit) 
    permissions = Authorization.get_person_permissions(users(:owner_of_custom_permissions_only_policy).person.id, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type > FavouriteGroup::WHITELIST_ACCESS_TYPE), "expected that the permission would give the test user more access than membership in the whitelist"
    
    # verify that being in whitelist wouldn't authorize the action
    temp = Authorization.access_type_allows_action?("edit", FavouriteGroup::WHITELIST_ACCESS_TYPE)
    assert (!temp), "whitelist solely shouldn't allow 'editing' otherwise this test case doesn't make sense"
    
    # verify that individual permission will be used, because whitelist doesn't have precedence
    res = Authorization.is_authorized?("edit", nil, sops(:sop_that_uses_whitelist_blacklist_and_custom_sharing), users(:owner_of_custom_permissions_only_policy))
    assert res, "test user should have been allowed to 'edit' the SOP having the individual permission and use_custom_sharing is set to true - whitelist membership should not have had precedence"
  end
  
  
  # testing favourite groups
  
  # someone with individual permission and in favourite group (more access than in individual permission) - permission in favourite group should never be used in such case
  def test_fav_group_permissions_dont_get_used_if_individual_permissions_exist
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_whitelist
    assert (!temp), "policy for test SOP shouldn't use whitelist"
    
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_blacklist
    assert (!temp), "policy for test SOP shouldn't use blacklist"
    
    # download is allowed for all registered users..
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_registered_users_policy).asset.policy, sops(:sop_with_all_registered_users_policy).asset, "download", 
                                               users(:random_registered_user_who_wants_to_access_different_things).id, users(:random_registered_user_who_wants_to_access_different_things).person.id)
    assert temp, "policy of the test SOP should have allowed 'download' of that asset"
    
    # ..but editing is not allowed
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_registered_users_policy).asset.policy, sops(:sop_with_all_registered_users_policy).asset, "edit", 
                                               users(:random_registered_user_who_wants_to_access_different_things).id, users(:random_registered_user_who_wants_to_access_different_things).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'edit' of that asset"
    
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    # verify that permissions for the user exist, but don't give enough access rights..
    permissions = Authorization.get_person_permissions(users(:random_registered_user_who_wants_to_access_different_things).person.id, sops(:sop_with_all_registered_users_policy).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type = Policy::VIEWING), "expected that the permission would give the test user viewing access to the test SOP, but no access for editing"
    
    # ..check that sharing with favourite group gives more access to this person..
    permissions = Authorization.get_person_access_rights_from_favourite_group_permissions(users(:random_registered_user_who_wants_to_access_different_things).person.id, sops(:sop_with_all_registered_users_policy).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type == Policy::EDITING), "expected that the permission would give the test user access to the test SOP for editing"
    
    # ..and now verify that permissions from favourite groups won't get used, because individual permissions have precedence
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_all_registered_users_policy), users(:random_registered_user_who_wants_to_access_different_things))
    assert (!res), "test user should not have been allowed to 'edit' the SOP - individual permission should have denied the action"
    
    res = Authorization.is_authorized?("download", nil, sops(:sop_with_all_registered_users_policy), users(:random_registered_user_who_wants_to_access_different_things))
    assert (!res), "test user should not have been allowed to 'download' the SOP - individual permission should have denied the action (these limit it to less that public access)"
    
    res = Authorization.is_authorized?("view", nil, sops(:sop_with_all_registered_users_policy), users(:random_registered_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'view' the SOP - this is what individual permissions only allow"
  end
  
  # someone with no individual permissions - hence the actual permission from being a member in a favourite group is used
  def test_fav_groups_permissions
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_whitelist
    assert (!temp), "policy for test SOP shouldn't use whitelist"
    
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_blacklist
    assert (!temp), "policy for test SOP shouldn't use blacklist"
    
    # editing is not allowed by policy (only download is)
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_registered_users_policy).asset.policy, sops(:sop_with_all_registered_users_policy).asset, "edit", 
                                               users(:owner_of_my_first_sop).id, users(:owner_of_my_first_sop).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'edit' of that asset"
    
    temp = sops(:sop_with_all_registered_users_policy).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    # verify that no individual permissions for the user exist..
    permissions = Authorization.get_person_permissions(users(:owner_of_my_first_sop).person.id, sops(:sop_with_all_registered_users_policy).asset.policy.id)
    assert (permissions.length == 0), "expected to have no permission in that policy for the test person, not #{permissions.length}"
    
    # ..check that sharing with favourite group gives some access to this person..
    permissions = Authorization.get_person_access_rights_from_favourite_group_permissions(users(:owner_of_my_first_sop).person.id, sops(:sop_with_all_registered_users_policy).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type == Policy::EDITING), "expected that the permission would give the test user access to the test SOP for editing"
    
    # ..and now verify that permissions from favourite groups are actually used
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_all_registered_users_policy), users(:owner_of_my_first_sop))
    assert res, "test user should have been allowed to 'edit' the SOP - because of favourite group membership and permissions"
  end
  
  # someone with favourite group permissions, but the 'use_custom_sharing' flag set to false
  def test_fav_group_permissions_are_not_used_when_use_custom_sharing_is_set_to_false
    :sop_with_all_sysmo_users_policy
    :owner_of_my_first_sop
    
    # ideally, would have checked that blacklist / whitelist are not used, but instead check that test
    # user is simply not listed in them (hence these won't modify any behaviour for test user)
    temp = Authorization.is_person_in_whitelist?(users(:owner_of_my_first_sop).person.id, sops(:sop_with_all_sysmo_users_policy).asset.contributor.id)
    assert (!temp), "test person shouldn't have been in the whitelist of the sop owner"
    
    temp = Authorization.is_person_in_blacklist?(users(:owner_of_my_first_sop).person.id, sops(:sop_with_all_sysmo_users_policy).asset.contributor.id)
    assert (!temp), "test person shouldn't have been in the blacklist of the sop owner"
    
    # download would be allowed by policy (even editing is)
    temp = Authorization.authorized_by_policy?(sops(:sop_with_all_sysmo_users_policy).asset.policy, sops(:sop_with_all_sysmo_users_policy).asset, "download", 
                                               users(:owner_of_my_first_sop).id, users(:owner_of_my_first_sop).person.id)
    assert temp, "policy of the test SOP should have allowed 'download' of that asset"
    
    temp = sops(:sop_with_all_sysmo_users_policy).asset.policy.use_custom_sharing
    assert (!temp), "'use_custom_sharing' flag should be set to 'false' for this test"
    
    # verify that no individual permissions for the user exist..
    permissions = Authorization.get_person_permissions(users(:owner_of_my_first_sop).person.id, sops(:sop_with_all_sysmo_users_policy).asset.policy.id)
    assert (permissions.length == 0), "expected to have no permission in that policy for the test person, not #{permissions.length}"
    
    # ..check that sharing with favourite group gives no access to this person..
    permissions = Authorization.get_person_access_rights_from_favourite_group_permissions(users(:owner_of_my_first_sop).person.id, sops(:sop_with_all_sysmo_users_policy).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission from favourite groups in that policy for the test person, not #{permissions.length}"
    assert (permissions[0].access_type == Policy::NO_ACCESS), "expected that the permission would give the test user no access to the test SOP"
    
    # ..and now verify that test user can download the SOP; favourite group permissions won't get applied because 'use_custom_sharing' flag is set to false
    res = Authorization.is_authorized?("download", nil, sops(:sop_with_all_sysmo_users_policy), users(:owner_of_my_first_sop))
    assert res, "test user should have been allowed to 'download' the SOP - because of favourite group permissions can't be applied, as 'use_custom_sharing' flag is set to 'false'"
  end
  
  
  # testing general policy settings
  
  def test_general_policy_settings_action_allowed
    # check that no permissions will be used..
    temp = sops(:sop_with_fully_public_policy).asset.policy.use_whitelist
    assert (!temp), "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_with_fully_public_policy).asset.policy.use_blacklist
    assert (!temp), "'use_blacklist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_with_fully_public_policy).asset.policy.use_custom_sharing
    assert (!temp), "'use_custom_sharing' flag should be set to 'false' for this test"
    
    # ..all flags are checked to 'false'; only policy settings will be used
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_fully_public_policy), users(:random_registered_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'edit' the SOP - it uses fully public policy"
  end
  
  def test_general_policy_settings_action_not_authorized
    # check that no permissions will be used..
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.use_whitelist
    assert (!temp), "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.use_blacklist
    assert (!temp), "'use_blacklist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.use_custom_sharing
    assert (!temp), "'use_custom_sharing' flag should be set to 'false' for this test"
    
    # ..all flags are checked to 'false'; only policy settings will be used
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_public_download_and_no_custom_sharing), users(:random_registered_user_who_wants_to_access_different_things))
    assert (!res), "test user shouldn't have been allowed to 'edit' the SOP - policy only allows downloading"
    
    res = Authorization.is_authorized?("download", nil, sops(:sop_with_public_download_and_no_custom_sharing), users(:random_registered_user_who_wants_to_access_different_things))
    assert res, "test user should have been allowed to 'download' the SOP - policy allows downloading"
  end
  
  
  # testing group permissions
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'WorkGroup'; "use_custom_permissions" flat set to 'true'
  def test_group_permissions_will_allow_action
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_workgroups).asset.policy.use_whitelist
    assert (!temp), "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_workgroups).asset.policy.use_blacklist
    assert (!temp), "'use_blacklist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_workgroups).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    # verify that action wouldn't be allowed by policy
    temp = Authorization.authorized_by_policy?(sops(:sop_for_test_with_workgroups).asset.policy, sops(:sop_for_test_with_workgroups).asset, "download", 
                                               users(:owner_of_fully_public_policy).id, users(:owner_of_fully_public_policy).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'download' of that asset"
    
    # verify that group permissions exist
    permissions = Authorization.get_group_permissions(sops(:sop_for_test_with_workgroups).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission for workgroups in that policy, not #{permissions.length}"
    assert (permissions[0].contributor_type == "WorkGroup"), "expected to have permission for 'WorkGroup'"
    assert (permissions[0].access_type == Policy::DOWNLOADING), "expected that the permission would give the test user download access to the test SOP"
    
    # verify that test user is a member of the group in the permission
    temp = Authorization.is_member?(users(:owner_of_fully_public_policy).person.id, permissions[0].contributor_type, permissions[0].contributor_id)
    
    # verify that group permissions work and access is granted
    res = Authorization.is_authorized?("download", nil, sops(:sop_for_test_with_workgroups), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'download' the SOP - because of group permission"
  end
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'WorkGroup'; "use_custom_permissions" flat set to 'false'
  def test_group_permissions_could_allow_action_but_use_custom_sharing_set_to_false
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_workgroups_no_custom_sharing).asset.policy.use_whitelist
    assert (!temp), "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_workgroups_no_custom_sharing).asset.policy.use_blacklist
    assert (!temp), "'use_blacklist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_workgroups_no_custom_sharing).asset.policy.use_custom_sharing
    assert (!temp), "'use_custom_sharing' flag should be set to 'false' for this test"
    
    # verify that action wouldn't be allowed by policy
    temp = Authorization.authorized_by_policy?(sops(:sop_for_test_with_workgroups_no_custom_sharing).asset.policy, sops(:sop_for_test_with_workgroups_no_custom_sharing).asset, "download", 
                                               users(:owner_of_fully_public_policy).id, users(:owner_of_fully_public_policy).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'download' of that asset"
    
    # verify that group permissions exist
    permissions = Authorization.get_group_permissions(sops(:sop_for_test_with_workgroups_no_custom_sharing).asset.policy.id)
    assert (permissions.length == 1), "expected to have one permission for workgroups in that policy, not #{permissions.length}"
    assert (permissions[0].contributor_type == "WorkGroup"), "expected to have permission for 'WorkGroup'"
    assert (permissions[0].access_type == Policy::DOWNLOADING), "expected that the permission would give the test user download access to the test SOP"
    
    # verify that test user is a member of the group in the permission
    temp = Authorization.is_member?(users(:owner_of_fully_public_policy).person.id, permissions[0].contributor_type, permissions[0].contributor_id)
    
    # verify that group permissions won't be applied and access is still prohibited
    res = Authorization.is_authorized?("download", nil, sops(:sop_for_test_with_workgroups_no_custom_sharing), users(:owner_of_fully_public_policy))
    assert (!res), "test user shouldn't have been allowed to 'download' the SOP - because group permission shouldn't be applied when 'use_custom_sharing' is set to 'false'"
    
    # viewing should still be allowed by the policy
    res = Authorization.is_authorized?("view", nil, sops(:sop_for_test_with_workgroups_no_custom_sharing), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'view' the SOP - because of policy settings"
  end
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'Project'; "use_custom_permissions" flat set to 'true'
  def test_group_permissions_shared_with_project
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_projects_institutions).asset.policy.use_whitelist
    assert (!temp), "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_projects_institutions).asset.policy.use_blacklist
    assert (!temp), "'use_blacklist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_projects_institutions).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    # verify that action wouldn't be allowed by policy
    temp = Authorization.authorized_by_policy?(sops(:sop_for_test_with_projects_institutions).asset.policy, sops(:sop_for_test_with_projects_institutions).asset, "edit", 
                                               users(:owner_of_download_for_all_registered_users_policy).id, users(:owner_of_download_for_all_registered_users_policy).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'edit' of that asset"
    
    # verify that group permissions exist
    permissions = Authorization.get_group_permissions(sops(:sop_for_test_with_projects_institutions).asset.policy.id)
    assert (permissions.length == 2), "expected to have 2 permission for workgroups in that policy, not #{permissions.length}"
    if permissions[0].contributor_type == "Project"
      perm = permissions[0]
    elsif permissions[1].contributor_type == "Project"
      perm = permissions[1]
    else
      perm = nil
    end
    assert (!perm.nil?), "couldn't find correct permission for the test"
    assert (perm.access_type == Policy::EDITING), "expected that the permission would give the test user edit access to the test SOP"
    
    # verify that test user is a member of the project in the permission
    temp = Authorization.is_member?(users(:owner_of_download_for_all_registered_users_policy).person.id, perm.contributor_type, perm.contributor_id)
    
    # verify that group permissions work and access is granted
    res = Authorization.is_authorized?("edit", nil, sops(:sop_for_test_with_projects_institutions), users(:owner_of_download_for_all_registered_users_policy))
    assert res, "test user should have been allowed to 'download' the SOP - because of group permission: shared with test user's project"
  end
  
  # no specific permissions; action not allowed by policy; allowed by a group permission for 'Institution'; "use_custom_permissions" flat set to 'true'
  def test_group_permissions_shared_with_institution
    # check that policy flags are set correctly
    temp = sops(:sop_for_test_with_projects_institutions).asset.policy.use_whitelist
    assert (!temp), "'use_whitelist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_projects_institutions).asset.policy.use_blacklist
    assert (!temp), "'use_blacklist' flag should be set to 'false' for this test"
    
    temp = sops(:sop_for_test_with_projects_institutions).asset.policy.use_custom_sharing
    assert temp, "'use_custom_sharing' flag should be set to 'true' for this test"
    
    # verify that action wouldn't be allowed by policy
    temp = Authorization.authorized_by_policy?(sops(:sop_for_test_with_projects_institutions).asset.policy, sops(:sop_for_test_with_projects_institutions).asset, "download", 
                                               users(:owner_of_fully_public_policy).id, users(:owner_of_fully_public_policy).person.id)
    assert (!temp), "policy of the test SOP shouldn't have allowed 'download' of that asset"
    
    # verify that group permissions exist
    permissions = Authorization.get_group_permissions(sops(:sop_for_test_with_projects_institutions).asset.policy.id)
    assert (permissions.length == 2), "expected to have 2 permission for workgroups in that policy, not #{permissions.length}"
    if permissions[0].contributor_type == "Institution"
      perm = permissions[0]
    elsif permissions[1].contributor_type == "Institution"
      perm = permissions[1]
    else
      perm = nil
    end
    assert (!perm.nil?), "couldn't find correct permission for the test"
    assert (perm.access_type == Policy::DOWNLOADING), "expected that the permission would give the test user download access to the test SOP"
    
    # verify that test user is a member of the institution in the permission
    temp = Authorization.is_member?(users(:owner_of_fully_public_policy).person.id, perm.contributor_type, perm.contributor_id)
    
    # verify that group permissions work and access is granted
    res = Authorization.is_authorized?("download", nil, sops(:sop_for_test_with_projects_institutions), users(:owner_of_fully_public_policy))
    assert res, "test user should have been allowed to 'download' the SOP - because of group permission: shared with test user's institution"
  end
  
  
  # testing anonymous users
  
  def test_anonymous_user_allowed_to_perform_an_action
    # it doesn't matter for this test case if any permissions exist for the policy -
    # these can't affect anonymous user; hence can only check the final result of authorization
    
    # verify that the policy really provides access to anonymous users
    temp = sops(:sop_with_fully_public_policy).asset.policy.sharing_scope
    temp2 = sops(:sop_with_fully_public_policy).asset.policy.access_type
    assert (temp == Policy::EVERYONE && temp2 > Policy::NO_ACCESS), "policy should provide some access for anonymous users for this test"
    
    res = Authorization.is_authorized?("edit", nil, sops(:sop_with_fully_public_policy), nil)
    assert res, "anonymous user should have been allowed to 'edit' the SOP - it uses fully public policy"
  end
  
  def test_anonymous_user_not_authorized_to_perform_an_action
    # it doesn't matter for this test case if any permissions exist for the policy -
    # these can't affect anonymous user; hence can only check the final result of authorization
    
    # verify that the policy really provides access to anonymous users
    temp = sops(:sop_with_public_download_and_no_custom_sharing).asset.policy.sharing_scope
    assert (temp < Policy::EVERYONE), "policy should not include anonymous users into the sharing scope"
    
    res = Authorization.is_authorized?("view", nil, sops(:sop_with_public_download_and_no_custom_sharing), nil)
    assert (!res), "anonymous user shouldn't have been allowed to 'view' the SOP - policy authorizes only registered users"
  end

  def test_downloadable_data_file
    data_file=data_files(:downloadable_data_file)
    res=Authorization.is_authorized?("download",DataFile,data_file,users(:aaron))
    assert res,"should be downloadable by all"
    assert data_file.can_download?(users(:aaron))
    res=Authorization.is_authorized?("edit",DataFile,data_file,users(:aaron))
    assert !res,"should not be editable"
    assert !data_file.can_edit?(users(:aaron))
  end

  def test_editable_data_file
    data_file=data_files(:editable_data_file)
    res=Authorization.is_authorized?("download",DataFile,data_file,users(:aaron))
    assert res,"should be downloadable by all"
    assert data_file.can_download?(users(:aaron))
    res=Authorization.is_authorized?("edit",DataFile,data_file,users(:aaron))
    assert res,"should be editable"
    assert data_file.can_edit?(users(:aaron))
  end

  def test_downloadable_sop
    sop=sops(:downloadable_sop)
    res=Authorization.is_authorized?("download",Sop,sop,users(:aaron))
    assert res,"Should be able to download"
    assert sop.can_download?(users(:aaron))

    assert sop.can_view? users(:aaron)

    res=Authorization.is_authorized?("edit",Sop,sop,users(:aaron))
    assert !res,"Should not be able to edit"
    assert !sop.can_edit?(users(:aaron))
  end

  def test_editable_sop
    sop=sops(:editable_sop)
    res=Authorization.is_authorized?("download",Sop,sop,users(:aaron))
    assert res,"Should be able to download"
    assert sop.can_download?(users(:aaron))

    assert sop.can_view?(users(:aaron))

    res=Authorization.is_authorized?("edit",Sop,sop,users(:aaron))
    assert res,"Should be able to edit"
    assert sop.can_edit?(users(:aaron))
  end
  
end
