module FunctionalAuthorizationTests
  def test_private_item_not_accessible_publicly
    itemname = @controller.controller_name.singularize.underscore
    another_user = Factory :user

    item = Factory itemname.to_sym, :policy => Factory(:private_policy)

    logout

    get :show,:id=>item.id
    assert_response :forbidden

  end

  def test_private_item_not_accessible_by_another_user
    itemname = @controller.controller_name.singularize.underscore
    another_user = Factory :user

    item = Factory itemname.to_sym, :policy => Factory(:private_policy)

    login_as(another_user)

    get :show,:id=>item.id
    assert_response :forbidden
  end

  def test_private_item_accessible_by_owner
    itemname = @controller.controller_name.singularize.underscore
    another_user = Factory :user

    item = Factory itemname.to_sym, :policy => Factory(:private_policy)

    contributor = item.contributor
    contributor = contributor.user if contributor.is_a?(Person)

    login_as(contributor)

    get :show,:id=>item.id
    assert_response :success
    assert_nil flash[:error]
  end
end