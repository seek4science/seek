require 'test_helper'

class FavouriteGroupsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  test 'add duplicate fails' do
    login_as(:owner_of_a_sop_with_complex_permissions)
    fav = favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions)
    user = fav.user

    # check that the user is the expected one for the test to be valid
    assert_equal users(:owner_of_a_sop_with_complex_permissions), user, 'Not the expected user, so the rest of the test is invalid'

    name = fav.name

    assert_no_difference('FavouriteGroup.count') do
      post :create, favourite_group_name: name, favourite_group_members: {}.to_json, format: 'json'
    end

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal 422, json_response['status']
  end

  test 'update duplicate fails' do
    login_as(:owner_of_a_sop_with_complex_permissions)
    fav = favourite_groups(:my_collaborators_group_for_owner_of_a_sop_with_complex_permissions)
    other_fav = favourite_groups(:whitelist_for_owner_of_a_sop_with_complex_permissions)
    user = fav.user

    # check that the user is the expected one for the test to be valid
    assert_equal users(:owner_of_a_sop_with_complex_permissions), user, 'Not the expected user, so the rest of the test is invalid'

    name = fav.name

    put :update, id: other_fav.id, favourite_group_name: name, favourite_group_members: {}.to_json, format: 'json'

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal 422, json_response['status']
  end
end
