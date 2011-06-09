require 'test_helper'

class PolicyTest < ActiveSupport::TestCase

  fixtures :all

  test "deep clone" do
    policy = policies(:download_for_all_registered_users_policy)

    copy = policy.deep_copy    
    assert_equal policy.sharing_scope,copy.sharing_scope
    assert_equal policy.access_type,copy.access_type
    assert_equal policy.name,copy.name
    assert_not_equal policy.id,copy.id

    assert policy.permissions.size>0,"needs to have custom permissions to make this test meaningful"
    assert copy.permissions.size>0,"needs to have custom permissions to make this test meaningful"

    assert_equal policy.permissions.size,copy.permissions.size

    policy.permissions.each_with_index do |perm,i|
      copy_perm = copy.permissions[i]
      assert_equal perm.contributor,copy_perm.contributor      
      assert_equal perm.access_type,copy_perm.access_type
      assert_not_equal perm.id,copy_perm.id      
    end
  end
  
  test "private policy" do
    pol=Policy.private_policy
    assert_equal Policy::PRIVATE, pol.sharing_scope
    assert_equal Policy::NO_ACCESS, pol.access_type
    assert_equal false,pol.use_whitelist
    assert_equal false,pol.use_blacklist
    assert pol.permissions.empty?
  end

  test "default policy" do
    pol=Policy.default
    assert_equal Policy::PRIVATE, pol.sharing_scope
    assert_equal Policy::NO_ACCESS, pol.access_type
    assert_equal false,pol.use_whitelist
    assert_equal false,pol.use_blacklist
    assert pol.permissions.empty?
  end

  test "policy access type presedence" do
    assert Policy::NO_ACCESS < Policy::VISIBLE
    assert Policy::VISIBLE < Policy::ACCESSIBLE
    assert Policy::ACCESSIBLE < Policy::EDITING
    assert Policy::EDITING < Policy::MANAGING
  end

  test "policy sharing scope presedence" do
    assert Policy::PRIVATE < Policy::ALL_SYSMO_USERS
    assert Policy::ALL_SYSMO_USERS < Policy::EVERYONE
  end

end
