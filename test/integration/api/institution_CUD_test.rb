require 'test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Institution
  end

  def setup
    admin_login
    
    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    inst = Factory(:institution)
    @to_post = load_template("post_min_#{singular_name}.json.erb", {title: "Post "+inst.title, country: inst.country})
  end

  def post_values
    { title: "Post Institition #{Institution.maximum(:id) + 1}", country: 'United Kingdom' }
  end

  def patch_values
    i = Factory(:institution)
    {id: i.id, country:'DE'}
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
