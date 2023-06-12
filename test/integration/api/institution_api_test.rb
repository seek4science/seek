require 'test_helper'

class InstitutionApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    admin_login
    @institution = FactoryBot.create(:institution)
  end

  def populate_extra_attributes(hash)
    extra_attributes = super

    if hash['data']['attributes'].has_key? 'country'
      extra_attributes[:country_code] = CountryCodes.code(hash['data']['attributes']['country'])
    end

    extra_attributes
  end

  test 'normal user cannot create institution' do
    user_login(FactoryBot.create(:person))
    body = api_max_post_body
    assert_no_difference('Institution.count') do
      post collection_url, params: body, as: :json
    end
  end
end
