require File.dirname(__FILE__) + '/../test_helper'

class PolicyTest < ActiveSupport::TestCase

  fixtures :all

  test "deep clone" do
    policy = policies(:download_for_all_registered_users_policy)

    copy = policy.deep_clone
    assert_equal policy.contributor,copy.contributor
    assert_equal policy.sharing_scope,copy.sharing_scope
    assert_equal policy.access_type,copy.access_type
    assert_equal policy.name,copy.name
    assert_not_equal policy.id,copy.id
    
    assert policy.use_custom_sharing
    assert copy.use_custom_sharing

    assert policy.permissions.size>0,"needs to have custom permissions to make this test meaningful"
    assert_equal policy.permissions.size,copy.permissions.size


    policy.permissions.each_with_index do |perm,i|
      copy_perm = copy.permissions[i]
      assert_equal perm.contributor,copy_perm.contributor      
      assert_equal perm.access_type,copy_perm.access_type
      assert_not_equal perm.id,copy_perm.id      
    end
  end

end
