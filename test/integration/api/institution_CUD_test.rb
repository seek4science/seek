require 'test_helper'

class InstitutionCUDTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def model
    Institution
  end

  def setup
    admin_login
    @institution = Factory(:institution)
  end

  def populate_extra_attributes(hash)
    extra_attributes = {}
    if hash['data']['attributes'].has_key? 'country'
      extra_attributes[:country_code] = CountryCodes.code(hash['data']['attributes']['country'])
    end
    extra_attributes.with_indifferent_access
  end

  test 'normal user cannot create institution' do
    user_login(Factory(:person))
    body = api_post_body
    assert_no_difference('Institution.count') do
      post collection_url, params: body, as: :json
    end
  end
end
