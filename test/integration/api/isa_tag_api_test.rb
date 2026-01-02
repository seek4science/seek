require 'test_helper'

class ISATagApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login
    @old_config = Seek::Config.isa_json_compliance_enabled || false
    Seek::Config.isa_json_compliance_enabled = true
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = @old_config
  end

  # Index test from read suite will fail because it requires you to be authenticated
  # The ISATagsControllerTest already tests getting the list of ISA Tags through the API
  def skip_index_test?
    true
  end

  test 'can get index if authenticated' do
    FactoryBot.create(:min_isa_tag)
    FactoryBot.create(:max_isa_tag)
    get '/isa_tags', as: :json, headers: { 'Accept': 'application/json', "Authorization": read_access_auth }

    perform_jsonapi_checks
    assert_nothing_raised { validate_json(response.body, index_response_fragment) }
  end

end
