require 'test_helper'
require 'minitest/mock'

class CollectionItemsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  test 'should create collection item' do
    collection = FactoryBot.create(:collection)
    doc = FactoryBot.create(:public_document)
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
    collection = FactoryBot.create(:collection, policy: FactoryBot.create(:private_policy))
    doc = FactoryBot.create(:public_document)
    login_as(FactoryBot.create(:person))

    refute collection.can_edit?

    assert_no_difference('CollectionItem.count') do
      post :create, params: { collection_id: collection.id, collection_item: { comment: 'Test', asset_type: 'Document', asset_id: doc.id } }
    end

    assert_redirected_to collection_path(collection)
    assert flash[:error].include?('authorized')
  end

  test 'should not reveal private asset in JSON' do
    private_asset = FactoryBot.create(:private_document)
    item = FactoryBot.create(:collection_item, asset: private_asset)
    get :show, format: 'json', params: { collection_id: item.collection_id, id: item.id }

    assert_response :success
    res = JSON.parse(response.body)
    assert_nil res['data']['relationships']['asset']
  end
end
