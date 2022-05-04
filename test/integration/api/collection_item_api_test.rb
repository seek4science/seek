require 'test_helper'

class CollectionItemApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    @collection = Factory(:collection, contributor: current_person)
    @document = Factory(:public_document, contributor: current_person)
    @sop = Factory(:sop, contributor: current_person, policy: Factory(:publicly_viewable_policy))
    @collection_item = Factory(:collection_item, collection: @collection)
  end

  def index_response_fragment
    "#/components/responses/collectionItemsResponse"
  end

  private

  def collection_url
    polymorphic_url([@collection, :items], format: :json)
  end

  def member_url(res)
    collection = res.is_a?(CollectionItem) ? res.collection : @collection
    polymorphic_url(res, collection_id: collection.id, format: :json)
  end
end
