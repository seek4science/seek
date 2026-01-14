# frozen_string_literal: true
require 'test_helper'

class ISATagsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :isa_tags

  def setup
    @authenticated_user = FactoryBot.create(:person)
    Seek::Config.isa_json_compliance_enabled = true
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = false
  end

  test 'should return available ISA tags' do
    login_as @authenticated_user

    get :index, as: :json
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal response_body["data"].count, 10
  end

  test 'should return the ISA tag by id' do
    login_as @authenticated_user
    get :show, as: :json, params: { id: ISATag.first.id }
    assert_response :success
  end

  test 'should not return ISA tags if not logged in' do
    get :index, as: :json
    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal response_body["errors"].first["title"], "Not Authenticated"
    assert_equal response_body["errors"].first["detail"], "Please log in."
  end

  test 'should not respond to anything else than json requests' do
    login_as @authenticated_user
    get :index, as: :xml
    assert_response :not_acceptable
    response_body = JSON.parse(response.body)
    assert_equal response_body["errors"].first["title"], "Not Acceptable"
    assert_equal response_body["errors"].first["detail"], "This endpoint only serves application/json."
  end

  test 'should not respond if ISA-JSON compliance is disabled' do
    with_config_value :isa_json_compliance_enabled, false do
      login_as @authenticated_user
      get :index, as: :json
      assert_response :forbidden
      response_body = JSON.parse(response.body)
      assert_equal response_body["errors"].first["title"], "Not Available"
      assert_equal response_body["errors"].first["detail"], "ISA-JSON compliance is disabled. Endpoint not available."
    end
  end
end