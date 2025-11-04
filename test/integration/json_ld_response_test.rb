require 'test_helper'

class JsonLdResponseTest < ActionDispatch::IntegrationTest

  include MockHelper
  def setup
    ror_mock
  end

  def teardown
    User.current_user = nil
  end

  Seek::Util.schema_org_supported_types.each do |type|
    # only if a controller exists
    controller = type.name.pluralize + "Controller"
    if Object.const_defined?(controller)
      test "jsonld response for #{type}" do
        check_for_type(type)
      end
    end
  end


  private

  def check_for_type(type)
    object = FactoryBot.create("max_#{type.model_name.singular}".to_sym)
    login_as_owner object.contributor.user if object.respond_to?(:contributor)
    assert object.can_view?, "#{type.name} expected to be visible"
    url = polymorphic_url(object, format: :jsonld)
    get url
    assert_response :success
    response = JSON.parse(@response.body)
    object = object.latest_version if object.respond_to?(:latest_version)
    expected = JSON.parse(object.to_schema_ld)
    assert_equal expected, response, "#{type.name} JSONLD expected to match"
  end


  def login_as_owner(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end

end