require 'test_helper'
require 'minitest/mock'

class CollectionItemsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  test 'should create collection item' do
    collection = Factory(:collection)
    doc = Factory(:public_document)
    login_as(collection.contributor)

    assert_difference('CollectionItem.count', 1) do
      post :create, params: { collection_id: collection.id, item: { comment: 'Test', asset_type: 'Document', asset_id: doc.id } }
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
      post :create, params: { collection_id: collection.id, item: { comment: 'Test', asset_type: 'Document', asset_id: doc.id } }
    end

    assert_redirected_to collection_path(collection)
    assert flash[:error].include?('authorized')
  end
end
