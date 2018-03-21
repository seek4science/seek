require 'test_helper'
require 'integration/api_test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "institution"
    @plural_clz = @clz.pluralize

    inst = Factory(:institution)
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: inst.id})

    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    @to_post = load_template("post_min_#{@clz}.json.erb", {title: "Post "+inst.title, country: inst.country})
  end

  def create_post_values
      i = Factory(:institution)
      @post_values = {title: "Post "+i.title, country: i.country}
  end

  def test_normal_user_cannot_create_institution
    user_login(Factory(:person))
    assert_no_difference('Institution.count') do
      post "/institutions.json", @to_post
    end
  end

end
