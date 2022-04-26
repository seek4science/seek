require 'test_helper'

class CollectionItemCUDTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def model
    CollectionItem
  end

  def setup
    admin_login
    @project = @current_user.person.projects.first
    @collection = Factory(:collection, contributor: current_person)
    @document = Factory(:public_document, contributor: current_person)
    @sop = Factory(:sop, contributor: current_person, policy: Factory(:publicly_viewable_policy))
    @collection_item = Factory(:collection_item, collection: @collection)
  end

  private

  def collection_url
    "/collections/#{@collection.id}/items.json"
  end

  def member_url(res)
    if res.is_a?(Numeric)
      id = res
      collection_id = @collection.id
    else
      id = res.id
      collection_id = res.collection_id
    end
    "/collections/#{collection_id}/items/#{id}.json"
  end
end
