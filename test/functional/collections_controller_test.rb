require 'test_helper'
require 'minitest/mock'

class CollectionsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  def test_json_content
    login_as(Factory(:user))
    super
  end

  def rest_api_test_object
    @object = Factory(:public_collection)
  end

  def edit_max_object(collection)
    add_tags_to_test_object(collection)
    add_creator_to_test_object(collection)
  end

  test 'should return 406 when requesting RDF' do
    login_as(Factory(:user))
    doc = Factory :collection, contributor: User.current_user.person
    assert doc.can_view?

    get :show, params: { id: doc, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryGirl.create_list(:public_collection, 3)

    get :index

    assert_response :success
    assert assigns(:collections).any?
  end

  test "shouldn't show hidden items in index" do
    visible_collection = Factory(:public_collection)
    hidden_collection = Factory(:private_collection)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:collections), visible_collection
    assert_not_includes assigns(:collections), hidden_collection
  end

  test 'should show' do
    visible_collection = Factory(:public_collection)

    get :show, params: { id: visible_collection }

    assert_response :success
  end

  test 'should show all item types without error' do
    all_types_collection = Factory(:collection_with_all_types)
    items = all_types_collection.collection_items

    get :show, params: { id: all_types_collection }

    assert_response :success
    items.each do |item|
      assert_select '#items-table tr a[href=?]', polymorphic_path(item.asset), "#{item.asset_type} collection item missing"
    end
  end

  test 'should not show hidden collection' do
    hidden_collection = Factory(:private_collection)

    get :show, params: { id: hidden_collection }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('collection')}"
  end

  test 'should get edit' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('collection')}"
  end

  test 'should create collection' do
    person = Factory(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('Collection.count') do
        post :create, params: { collection: { title: 'Collection', project_ids: [person.projects.first.id]}, policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'should update collection' do
    person = Factory(:person)
    collection = Factory(:collection, contributor: person)
    login_as(person)

    assert collection.assays.empty?

    assert_difference('ActivityLog.count') do
      put :update, params: { id: collection.id, collection: { title: 'Different title', project_ids: [person.projects.first.id] } }
    end

    assert_redirected_to collection_path(assigns(:collection))
    assert_equal 'Different title', assigns(:collection).title
  end

  test 'should destroy collection' do
    person = Factory(:person)
    collection = Factory(:populated_collection, contributor: person)
    login_as(person)

    assert_difference('Collection.count', -1) do
      assert_difference('CollectionItem.count', -1) do
        delete :destroy, params: { id: collection }

        assert_redirected_to collections_path
      end
    end
  end

  test "asset collections through nested routing" do
    assert_routing 'documents/2/collections', controller: 'collections', action: 'index', document_id: '2'
    person = Factory(:person)
    login_as(person)
    collection = Factory(:populated_collection, contributor: person)
    collection2 = Factory(:populated_collection, contributor: person)
    document = collection.assets.first

    get :index, params: { document_id: document.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', collection_path(collection), text: collection.title
      assert_select 'a[href=?]', collection_path(collection2), text: collection2.title, count: 0
    end
  end

  test "people collections through nested routing" do
    assert_routing 'people/2/collections', controller: 'collections', action: 'index', person_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    collection = Factory(:collection,assays:[assay],contributor:person)
    collection2 = Factory(:collection,policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', collection_path(collection), text: collection.title
      assert_select 'a[href=?]', collection_path(collection2), text: collection2.title, count: 0
    end
  end

  test "project collections through nested routing" do
    assert_routing 'projects/2/collections', controller: 'collections', action: 'index', project_id: '2'
    person = Factory(:person)
    login_as(person)
    collection = Factory(:collection, contributor:person)
    collection2 = Factory(:collection,policy: Factory(:public_policy), contributor:Factory(:person))

    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', collection_path(collection), text: collection.title
      assert_select 'a[href=?]', collection_path(collection2), text: collection2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('collection')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    collection = Factory(:collection, contributor:person)
    login_as(person)
    assert collection.can_manage?
    get :manage, params: {id: collection}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    collection = Factory(:collection, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert collection.can_edit?
    refute collection.can_manage?
    get :manage, params: {id:collection}
    assert_redirected_to collection
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    collection = Factory(:collection, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert collection.can_manage?

    patch :manage_update, params: {id: collection,
                                   collection: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to collection

    collection.reload
    assert_equal [proj1,proj2],collection.projects.sort_by(&:id)
    assert_equal [other_creator],collection.creators
    assert_equal Policy::VISIBLE,collection.policy.access_type
    assert_equal 1,collection.policy.permissions.count
    assert_equal other_person,collection.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,collection.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    collection = Factory(:collection, projects:[proj1], policy:Factory(:private_policy,
                                                         permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute collection.can_manage?
    assert collection.can_edit?

    assert_equal [proj1],collection.projects
    assert_empty collection.creators

    patch :manage_update, params: {id: collection,
                                   collection: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    collection.reload
    assert_equal [proj1],collection.projects
    assert_empty collection.creators
    assert_equal Policy::PRIVATE,collection.policy.access_type
    assert_equal 1,collection.policy.permissions.count
    assert_equal person,collection.policy.permissions.first.contributor
    assert_equal Policy::EDITING,collection.policy.permissions.first.access_type
  end

  test 'numeric pagination' do
    FactoryGirl.create_list(:public_collection, 20)

    with_config_value(:results_per_page_default, 5) do
      get :index

      assert_equal 5, assigns(:collections).length
      assert_equal '1', assigns(:page)
      assert_equal 5, assigns(:per_page)
      assert_select '.pagination-container a', href: collections_path(page: 2), text: /Next/
      assert_select '.pagination-container a', href: collections_path(page: 2), text: /2/
      assert_select '.pagination-container a', href: collections_path(page: 3), text: /3/

      get :index, params: { page: 2 }

      assert_equal 5, assigns(:collections).length
      assert_equal '2', assigns(:page)
      assert_select '.pagination-container a', href: collections_path(page: 3), text: /Next/
      assert_select '.pagination-container a', href: collections_path(page: 1), text: /Previous/
      assert_select '.pagination-container a', href: collections_path(page: 1), text: /1/
      assert_select '.pagination-container a', href: collections_path(page: 3), text: /3/
    end
  end

  test 'user can change results per page' do
    FactoryGirl.create_list(:public_collection, 15)

    with_config_value(:results_per_page_default, 5) do
      get :index, params: { per_page: 15 }
      assert_equal 15, assigns(:collections).length
      assert_equal '1', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0

      get :index, params: { per_page: 15, page: 2 }
      assert_equal 0, assigns(:collections).length
      assert_equal '2', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0
    end
  end

  test 'show filters on index' do
    Factory(:public_collection)

    get :index
    assert_select '.index-filters', count: 1
  end

  test 'do not show filters on index if disabled' do
    Factory(:public_collection)

    with_config_value(:filtering_enabled, false) do
      get :index
      assert_select '.index-filters', count: 0
    end
  end

  test 'should update collection items' do
    person = Factory(:person)
    collection = Factory(:collection, contributor: person)
    item1 = collection.items.create(asset: Factory(:public_document), order: 1, comment: 'First doc')
    item2 = collection.items.create(asset: Factory(:public_document), order: 2, comment: 'Second doc')
    item3 = collection.items.create(asset: Factory(:public_document), order: 3, comment: 'Third doc')
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('CollectionItem.count', -1) do
        put :update, params: { id: collection.id, collection: { title: 'Different title', items_attributes: {
            '1' => { id: item1.id, order: 1, comment: 'First doc'},
            '2' => { id: item2.id, order: 2, comment: 'First doc', _destroy: '1' },
            '3' => { id: item3.id, order: 2, comment: 'Second doc'},
        } } }
      end
    end

    assert_redirected_to collection_path(assigns(:collection))
    assert_equal 'Different title', assigns(:collection).title
    assert_equal 'Second doc', item3.reload.comment
    assert_equal 2, item3.order
    refute CollectionItem.exists?(item2.id)
  end

  test 'should not show items linked to private assets' do
    person = Factory(:person)
    collection = Factory(:collection, contributor: person)
    public = collection.items.create(asset: Factory(:public_document), order: 1, comment: 'This doc is public')
    private = collection.items.create(asset: Factory(:private_document), order: 2, comment: 'This doc is not')
    assert collection.can_view?
    assert public.asset.can_view?
    refute private.asset.can_view?

    get :show, params: { id: collection.id }

    assert_response :success
    assert_select 'li a[href=?]', document_path(public.asset)
    assert_select 'li a[href=?]', document_path(private.asset), count: 0
  end

  test 'should not show items linked to private assets even in edit form' do
    person = Factory(:person)
    collection = Factory(:collection, contributor: person)
    public = collection.items.create(asset: Factory(:public_document), order: 1, comment: 'This doc is public')
    private = collection.items.create(asset: Factory(:private_document), order: 2, comment: 'This doc is not')
    assert collection.can_view?
    assert public.asset.can_view?
    refute private.asset.can_view?

    login_as(person)

    get :edit, params: { id: collection.id }

    assert_response :success
    assert_select '#items-table tr a[href=?]', document_path(public.asset)
    assert_select '#items-table tr a[href=?]', document_path(private.asset), count: 0
  end

  test 'should cope with an asset in the collection being deleted' do
    person = Factory(:person)
    collection = Factory(:collection, contributor: person)
    document = Factory(:public_document)
    item = collection.items.create(asset: document)
    disable_authorization_checks { document.destroy! }

    get :show, params: { id: collection.id }

    assert_response :success
    assert_select 'li a[href=?]', document_path(document), count: 0
  end

  private

  def valid_collection
    { title: 'Test', project_ids: [projects(:sysmo_project).id] }
  end
end
