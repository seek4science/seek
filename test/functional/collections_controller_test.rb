require 'test_helper'
require 'minitest/mock'

class CollectionsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  test 'should return 406 when requesting RDF' do
    login_as(FactoryBot.create(:user))
    doc = FactoryBot.create :collection, contributor: User.current_user.person
    assert doc.can_view?

    get :show, params: { id: doc, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryBot.create_list(:public_collection, 3)

    get :index

    assert_response :success
    assert assigns(:collections).any?
  end

  test 'should not duplicate maintainer' do
    person = FactoryBot.create(:person)
    login_as(person.user)
    collection = FactoryBot.create(:public_collection, title: 'my collection',contributor:person, creators:[person, FactoryBot.create(:person)])

    get :index
    assert_response :success
    assert_equal 1, assigns(:collections).count

    assert_select 'div.list_item' do
      assert_select '.list_item_title', text:'my collection'
      assert_select '.rli-person-list a[href=?]',person_path(person),count:1
    end
  end

  test "shouldn't show hidden items in index" do
    visible_collection = FactoryBot.create(:public_collection)
    hidden_collection = FactoryBot.create(:private_collection)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:collections), visible_collection
    assert_not_includes assigns(:collections), hidden_collection
  end

  test 'should show' do
    visible_collection = FactoryBot.create(:public_collection)

    get :show, params: { id: visible_collection }

    assert_response :success
  end

  test 'should show all item types without error' do
    all_types_collection = FactoryBot.create(:collection_with_all_types)
    items = all_types_collection.items
    assert items.any?

    get :show, params: { id: all_types_collection }

    assert_response :success
    items.each do |item|
      assert_select 'ul.feed li a[href=?]', Seek::Util.routes.polymorphic_path(item.asset)
    end
  end

  test 'should not show hidden collection' do
    hidden_collection = FactoryBot.create(:private_collection)

    get :show, params: { id: hidden_collection }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('collection')}"
  end

  test 'should get edit' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('collection')}"
  end

  test 'should create collection' do
    person = FactoryBot.create(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('Collection.count') do
        post :create, params: { collection: { title: 'Collection', project_ids: [person.projects.first.id]}, policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'create, update and show a collection with extended metadata' do
    cmt = FactoryBot.create(:simple_collection_extended_metadata_type)

    person = FactoryBot.create(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('Collection.count') do
        assert_difference('ExtendedMetadata.count') do
          post :create, params: { collection: { title: 'Collection', project_ids: [person.projects.first.id],
                                                extended_metadata_attributes:{ extended_metadata_type_id: cmt.id,
                                                                               data:{ 'age': 22,'name':'fred'}}},
                                  policy_attributes: valid_sharing }

        end
      end
    end

    assert collection = assigns(:collection)
    cm = collection.extended_metadata

    assert_equal cmt, cm.extended_metadata_type
    assert_equal 'fred',cm.get_attribute_value('name')
    assert_equal 22,cm.get_attribute_value('age')
    assert_nil cm.get_attribute_value('date')


    get :show, params: { id: collection }
    assert_response :success

    assert_select 'div.extended_metadata',text:/fred/, count:1
    assert_select 'div.extended_metadata',text:/22/, count:1

    # test update
    old_id = cm.id
    assert_no_difference('Collection.count') do
      assert_no_difference('ExtendedMetadata.count') do
        put :update, params: { id: collection.id, collection: { title: "new title",
                                                            extended_metadata_attributes: { extended_metadata_type_id: cmt.id, id: cm.id,
                                                                                            data: {
                                                                                              "age": 20,
                                                                                              "name": 'max'
                                                                                            } }
        }
        }
      end
    end


    assert new_collection = assigns(:collection)
    assert_equal 'new title', new_collection.title
    assert_equal 'max', new_collection.extended_metadata.get_attribute_value('name')
    assert_equal 20, new_collection.extended_metadata.get_attribute_value('age')
    assert_equal old_id, new_collection.extended_metadata.id
  end

  test 'should update collection' do
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, contributor: person)
    login_as(person)

    assert collection.assays.empty?

    assert_difference('ActivityLog.count') do
      put :update, params: { id: collection.id, collection: { title: 'Different title', project_ids: [person.projects.first.id] } }
    end

    assert_redirected_to collection_path(assigns(:collection))
    assert_equal 'Different title', assigns(:collection).title
  end

  test 'should destroy collection' do
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:populated_collection, contributor: person)
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
    person = FactoryBot.create(:person)
    login_as(person)
    collection = FactoryBot.create(:populated_collection, contributor: person)
    collection2 = FactoryBot.create(:populated_collection, contributor: person)
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
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor:person)
    collection = FactoryBot.create(:collection,assays:[assay],contributor:person)
    collection2 = FactoryBot.create(:collection,policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', collection_path(collection), text: collection.title
      assert_select 'a[href=?]', collection_path(collection2), text: collection2.title, count: 0
    end
  end

  test "project collections through nested routing" do
    assert_routing 'projects/2/collections', controller: 'collections', action: 'index', project_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    collection = FactoryBot.create(:collection, contributor:person)
    collection2 = FactoryBot.create(:collection,policy: FactoryBot.create(:public_policy), contributor:FactoryBot.create(:person))

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
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, contributor:person)
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
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert collection.can_edit?
    refute collection.can_manage?
    get :manage, params: {id:collection}
    assert_redirected_to collection
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = FactoryBot.create(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    collection = FactoryBot.create(:collection, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

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
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = FactoryBot.create(:person)

    other_creator = FactoryBot.create(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    collection = FactoryBot.create(:collection, projects:[proj1], policy:FactoryBot.create(:private_policy,
                                                         permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

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
    FactoryBot.create_list(:public_collection, 20)

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
    FactoryBot.create_list(:public_collection, 15)

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
    FactoryBot.create(:public_collection)

    get :index
    assert_select '.index-filters', count: 1
  end

  test 'do not show filters on index if disabled' do
    FactoryBot.create(:public_collection)

    with_config_value(:filtering_enabled, false) do
      get :index
      assert_select '.index-filters', count: 0
    end
  end

  test 'should update collection items' do
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, contributor: person)
    item1 = collection.items.create(asset: FactoryBot.create(:public_document), order: 1, comment: 'First doc')
    item2 = collection.items.create(asset: FactoryBot.create(:public_document), order: 2, comment: 'Second doc')
    item3 = collection.items.create(asset: FactoryBot.create(:public_document), order: 3, comment: 'Third doc')
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
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, contributor: person)
    public = collection.items.create(asset: FactoryBot.create(:public_document), order: 1, comment: 'This doc is public')
    private = collection.items.create(asset: FactoryBot.create(:private_document), order: 2, comment: 'This doc is not')
    assert collection.can_view?
    assert public.asset.can_view?
    refute private.asset.can_view?

    get :show, params: { id: collection.id }

    assert_response :success
    assert_select 'li a[href=?]', document_path(public.asset)
    assert_select 'li a[href=?]', document_path(private.asset), count: 0
  end

  test 'should not show items linked to private assets even in edit form' do
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, contributor: person)
    public = collection.items.create(asset: FactoryBot.create(:public_document), order: 1, comment: 'This doc is public')
    private = collection.items.create(asset: FactoryBot.create(:private_document), order: 2, comment: 'This doc is not')
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
    person = FactoryBot.create(:person)
    collection = FactoryBot.create(:collection, contributor: person)
    document = FactoryBot.create(:public_document)
    item = collection.items.create(asset: document)
    disable_authorization_checks { document.destroy! }

    get :show, params: { id: collection.id }

    assert_response :success
    assert_select 'li a[href=?]', document_path(document), count: 0
  end

  test 'do not get index if feature disabled' do
    with_config_value(:collections_enabled, false) do
      get :index
      assert_redirected_to root_path
      assert flash[:error].include?('disabled')
    end
  end

  private

  def valid_collection
    { title: 'Test', project_ids: [projects(:sysmo_project).id] }
  end
end
