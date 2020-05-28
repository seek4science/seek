require 'test_helper'
require 'integration/api_test_helper'

class CollectionItemCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'collection_item'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    @collection = Factory(:collection, contributor: @current_person)
    @document = Factory(:public_document, contributor: @current_person)
    @sop = Factory(:sop, contributor: @current_person, policy: Factory(:publicly_viewable_policy))

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_collection_item.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    collection_item = Factory(:collection_item, contributor: @current_person)
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: collection_item.id})
  end

  private

  def collection_url
    "/collections/#{@collection.id}/items.json"
  end

  def member_url(obj)
    "/collections/#{obj.collection_id}/items/#{obj.id}.json"
  end
end
