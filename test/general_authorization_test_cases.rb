# module mixed in with functional tests to test some general authorization scenerios common to all assets

module GeneralAuthorizationTestCases
  def test_private_item_not_accessible_publicly
    itemname = @controller.controller_name.singularize.underscore

    item = Factory itemname.to_sym, policy: Factory(:private_policy)

    logout

    get :show, params: { id: item.id }
    assert_response :forbidden

    unless RestTestCases::SKIPPED_JSON.include?(item.class.name)
      get :show, params: { id: item.id, format: 'json' }
      assert_response :forbidden
    end
  end

  def test_private_item_not_accessible_by_another_user
    itemname = @controller.controller_name.singularize.underscore
    another_user = Factory :user

    item = Factory itemname.to_sym, policy: Factory(:private_policy)

    login_as(another_user)

    get :show, params: { id: item.id }
    assert_response :forbidden

    unless RestTestCases::SKIPPED_JSON.include?(item.class.name)
      get :show, params: { id: item.id, format: 'json' }
      assert_response :forbidden
    end
  end

  def test_private_item_accessible_by_owner
    itemname = @controller.controller_name.singularize.underscore

    item = Factory itemname.to_sym, policy: Factory(:private_policy)

    contributor = item.contributor

    login_as(contributor)

    get :show, params: { id: item.id }
    assert_response :success
    assert_nil flash[:error]

    unless RestTestCases::SKIPPED_JSON.include?(item.class.name)
      get :show, params: { id: item.id, format: 'json' }
      assert_response :success
    end
  end

  def check_manage_edit_menu_for_type(type)
    person = Factory(:person)
    login_as(person)
    editable = Factory(type.to_sym, policy: Factory(:private_policy, permissions: [Factory(:permission, contributor: person, access_type: Policy::EDITING)]))
    manageable = Factory(type.to_sym, contributor: person, policy: Factory(:private_policy))

    assert editable.can_edit?
    refute editable.can_manage?
    assert manageable.can_manage?

    get :show, params: { id: editable.id }
    assert_response :success

    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a[href=?]', send("edit_#{type}_path", editable), text: /Edit/, count: 1
      assert_select 'li > a[href=?]', send("manage_#{type}_path", editable), text: /Manage/, count: 0
    end

    get :show, params: { id: manageable.id }
    assert_response :success

    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a[href=?]', send("edit_#{type}_path", manageable), text: /Edit/, count: 1
      assert_select 'li > a[href=?]', send("manage_#{type}_path", manageable), text: /Manage/, count: 1
    end
  end
end
