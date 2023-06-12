# module mixed in with functional tests to test some general authorization scenerios common to all assets

module GeneralAuthorizationTestCases
  extend ActiveSupport::Testing::Declarative

  test 'private item not accessible publicly' do
    itemname = @controller.controller_name.singularize.underscore

    item = FactoryBot.create itemname.to_sym, policy: FactoryBot.create(:private_policy)

    logout

    get :show, params: { id: item.id }
    assert_response :forbidden

    if @controller.class.api_actions.include?(:show)
      get :show, params: { id: item.id, format: 'json' }
      assert_response :forbidden
    end
  end

  test 'private item not accessible by another user' do
    itemname = @controller.controller_name.singularize.underscore
    another_user = FactoryBot.create :user

    item = FactoryBot.create itemname.to_sym, policy: FactoryBot.create(:private_policy)

    login_as(another_user)

    get :show, params: { id: item.id }
    assert_response :forbidden

    if @controller.class.api_actions.include?(:show)
      get :show, params: { id: item.id, format: 'json' }
      assert_response :forbidden
    end
  end

  test 'private item accessible by owner' do
    itemname = @controller.controller_name.singularize.underscore

    item = FactoryBot.create itemname.to_sym, policy: FactoryBot.create(:private_policy)

    contributor = item.contributor

    login_as(contributor)

    get :show, params: { id: item.id }
    assert_response :success
    assert_nil flash[:error]

    if @controller.class.api_actions.include?(:show)
      get :show, params: { id: item.id, format: 'json' }
      assert_response :success
    end
  end

  def check_manage_edit_menu_for_type(type)
    person = FactoryBot.create(:person)
    login_as(person)
    editable = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::EDITING)]))
    manageable = FactoryBot.create(type.to_sym, contributor: person, policy: FactoryBot.create(:private_policy))

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
