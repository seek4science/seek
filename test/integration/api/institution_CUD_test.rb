require 'test_helper'
require 'integration/api_test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "institution"
    @plural_clz = @clz.pluralize

    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    inst = Factory(:institution)
    @to_post = load_template("post_min_#{@clz}.json.erb", {title: "Post "+inst.title, country: inst.country})
  end

  def create_post_values
      i = Factory(:institution)
      @post_values = {title: "Post "+i.title, country: 'United Kingdom'}
  end

  def create_patch_values
    i = Factory(:institution)
    @patch_values = {id: i.id, country:'DE'}
  end

  def ignore_non_read_or_write_attributes
    ['country_code']
  end

  def populate_extra_attributes(hash)
    extra_attributes = {}
    if hash['data']['attributes'].has_key? 'country'
      extra_attributes[:country_code] = CountryCodes.code(hash['data']['attributes']['country'])
    end
    extra_attributes.with_indifferent_access
  end

  def test_normal_user_cannot_create_institution
    user_login(Factory(:person))
    assert_no_difference('Institution.count') do
      post "/institutions.json", params: @to_post
    end
  end

end
