require 'test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Institution
  end

  def setup
    admin_login
  end

  def post_values
    { title: "Post Institition #{Institution.maximum(:id) + 1}", country: 'United Kingdom' }
  end

  def patch_values
    { country:'DE'}
  end

  def ignore_non_read_or_write_attributes
    super | ['country_code']
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
    json = post_json
    assert_no_difference('Institution.count') do
      post "/institutions.json", params: json
    end
  end

end
