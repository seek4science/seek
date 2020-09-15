require 'test_helper'
require 'minitest/mock'

class CollectionItemsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  test 'should create collection item' do
    collection = Factory(:collection)
    doc = Factory(:public_document)
    login_as(collection.contributor)

    assert_difference('CollectionItem.count', 1) do
      post :create, params: { collection_id: collection.id, collection_item: { comment: 'Test', asset_type: 'Document', asset_id: doc.id } }
    end

    assert_redirected_to collection_path(collection)
    assert flash[:notice].include?('added')
    item = collection.items.last
    assert_equal doc, item.asset
    assert_equal 'Test', item.comment
    assert_equal 1, item.order, 'Order should be automatically generated'
  end

  test 'should not create collection item if no edit rights' do
    collection = Factory(:collection, policy: Factory(:private_policy))
    doc = Factory(:public_document)
    login_as(Factory(:person))

    refute collection.can_edit?

    assert_no_difference('CollectionItem.count') do
      post :create, params: { collection_id: collection.id, collection_item: { comment: 'Test', asset_type: 'Document', asset_id: doc.id } }
    end

    assert_redirected_to collection_path(collection)
    assert flash[:error].include?('authorized')
  end

  test 'should not reveal private asset in JSON' do
    private_asset = Factory(:private_document)
    item = Factory(:collection_item, asset: private_asset)
    get :show, format: 'json', params: { collection_id: item.collection_id, id: item.id }

    assert_response :success
    res = JSON.parse(response.body)
    assert_nil res['data']['relationships']['asset']
  end

  def rest_api_test_object
    @object ||= Factory(:collection_item)
  end

  def rest_index_url_options(collection = rest_api_test_object.collection)
    { collection_id: collection.id }
  end

  def rest_show_url_options(collection_item = rest_api_test_object)
    { collection_id: collection_item.collection_id }
  end
end
