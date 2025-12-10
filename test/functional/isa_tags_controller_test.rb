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

  test 'should return ISA tags if logged in' do
    login_as @authenticated_user

    get :index, as: :json
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal response_body["data"].count, 10
  end

  test 'should not return ISA tags if not logged in' do
    get :index, as: :json
    assert_response :unauthorized
    assert_equal response.body, "HTTP Basic: Access denied.\n"
  end

  test 'should not respond to anything else than json requests' do
    get :index, as: :xml
    assert_response :not_acceptable
    response_body = JSON.parse(response.body)
    assert_equal response_body["error"], "Not Acceptable"
  end

end