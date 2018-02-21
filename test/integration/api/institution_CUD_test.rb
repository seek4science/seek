require 'test_helper'
require 'integration/api_test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "institution"
    @plural_clz = @clz.pluralize

    inst = Factory(:institution)
    @to_patch = load_template("patch_#{@clz}.json.erb", {id: inst.id})

    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    @to_post = load_template("post_min_#{@clz}.json.erb", {title: "Post "+inst.title, country: inst.country})
  end

  #no need for this to be called for every possible test (upon setup)
  def create_post_values
    @post_values = {}
    ['min','max'].each do |m|
      i = Factory(:institution)
      @post_values[m] = {title: "Post "+i.title, country: i.country}
    end
  end

  def test_normal_user_cannot_create_institution
    user_login(Factory(:person))
    assert_no_difference('Institution.count') do
      post "/institutions.json", @to_post
    end
  end

  def test_normal_user_cannot_update_institution
    user_login(Factory(:person))
    @to_patch["data"]["attributes"]["title"] = "update institution fails for a normal user"
    patch "/institutions/#{@to_patch["data"]["id"]}.json", @to_patch
    assert_response :forbidden
  end

  def test_normal_user_cannot_delete_institution
    user_login(Factory(:person))
    inst = Factory(:institution)
    assert_no_difference('Institution.count') do
      delete "/institutions/#{inst.id}.json"
      assert_response :forbidden
    end
  end

end
