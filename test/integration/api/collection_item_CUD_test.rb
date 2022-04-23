require 'test_helper'

class CollectionItemCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    CollectionItem
  end

  def resource
    Factory(:collection_item, collection: @collection)
  end

  def setup
    admin_login
    @project = @current_user.person.projects.first
    @collection = Factory(:collection, contributor: current_person)
    @document = Factory(:public_document, contributor: current_person)
    @sop = Factory(:sop, contributor: current_person, policy: Factory(:publicly_viewable_policy))
  end

  private

  def collection_url
    "/collections/#{@collection.id}/items.json"
  end

  def member_url(obj)
    "/collections/#{obj.collection_id}/items/#{obj.id}.json"
  end
end
