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

  def check_publish_menu_for_type(type)

    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    policy = FactoryBot.create(:policy, access_type: Policy::NO_ACCESS, permissions: [FactoryBot.create(:permission)])
    publishable = FactoryBot.create(type.to_sym, project_ids: gatekeeper.projects.collect(&:id), policy: policy)
    person = publishable.contributor
    pub_policy = FactoryBot.create(:policy, access_type: Policy::ACCESSIBLE, permissions: [FactoryBot.create(:permission)])
    published = FactoryBot.create(type.to_sym, project_ids: FactoryBot.create(:project).id, contributor: person, policy: pub_policy)
    editable = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: person, access_type: Policy::EDITING)]))

    login_as(person)

    # Published button not available if already public
    assert published.can_manage?
    assert published.is_published?
    get :show, params: { id: published.id }
    assert_response :success
    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a', text: /publish/, count: 0
    end

    # Publish button not available if cannot manage
    assert_not editable.can_manage?
    assert_not editable.is_published?
    get :show, params: { id: published.id }
    assert_response :success
    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a', text: /publish/, count: 0
    end

    # Publish and cancel publishing request buttons for manageable items
    assert publishable.can_manage?
    assert publishable.can_publish?
    assert publishable.gatekeeper_required?

    ## Publish button available if unpublished
    get :show, params: { id: publishable.id }
    assert_response :success
    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a[href=?]', send("check_related_items_#{type}_path", publishable), text: /Publish/, count: 1
    end

    ## Cancel publishing request button not available if neither waiting approval or rejected
    refute publishable.is_waiting_approval?
    refute publishable.is_rejected?
    get :show, params: { id: publishable.id }
    assert_response :success

    assert_select 'li > a[href=?]', cancel_publishing_request_person_path(person,
                                         { asset_id: publishable.id, asset_class: publishable.class, from_asset: true }),
                  text: /Cancel publishing request/, count: 0
    assert_select 'li > a', text: /publish/, count: 0


    ## Cancel publishing request button available if waiting approval
    ResourcePublishLog.add_log ResourcePublishLog::WAITING_FOR_APPROVAL, publishable
    publishable.reload
    assert publishable.is_waiting_approval?
    get :show, params: { id: publishable.id }
    assert_response :success
    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a[href=?]', cancel_publishing_request_person_path(person,
      { asset_id: publishable.id, asset_class: publishable.class, from_asset: true }),
      text: /Cancel publishing request/, count: 1
      assert_select 'li > a', text: /publish/, count: 1
    end

    ## Cancel publishing request button available if rejected
    ResourcePublishLog.add_log ResourcePublishLog::REJECTED, publishable
    publishable.reload
    assert publishable.is_rejected?
    get :show, params: { id: publishable.id }
    assert_response :success
    assert_select 'ul#item-admin-menu' do
      assert_select 'li > a[href=?]', cancel_publishing_request_person_path(person,
      { asset_id: publishable.id, asset_class: publishable.class, from_asset: true }),
      text: /Cancel publishing request/, count: 1
      assert_select 'li > a', text: /publish/, count: 1
    end

    ## Cancel publishing request not available if cannot manage
    other_person = FactoryBot.create(:person)
    publishable.policy.update_column(:access_type, Policy::VISIBLE)
    login_as(other_person)
    refute publishable.can_manage?
    assert publishable.can_view?
    assert publishable.is_rejected?
    get :show, params: { id: publishable.id }
    assert_response :success

    assert_select 'li > a[href=?]', cancel_publishing_request_person_path(person,
                                         { asset_id: publishable.id, asset_class: publishable.class, from_asset: true }),
                  text: /Cancel publishing request/, count: 0
    assert_select 'li > a', text: /publish/, count: 0


    ## Cancel publishing request not available if logged out
    logout
    refute publishable.can_manage?
    assert publishable.is_rejected?
    get :show, params: { id: publishable.id }
    assert_response :success

    assert_select 'li > a[href=?]', cancel_publishing_request_person_path(person,
                                         { asset_id: publishable.id, asset_class: publishable.class, from_asset: true }),
                  text: /Cancel publishing request/, count: 0
    assert_select 'li > a', text: /publish/, count: 0

  end
end
