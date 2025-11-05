require 'test_helper'

class JsonLdResponseTest < ActionDispatch::IntegrationTest
  include MockHelper
  def setup
    ror_mock
    @default_user = FactoryBot.create(:user)
  end

  def teardown
    User.current_user = nil
  end

  Seek::Util.schema_org_supported_types.each do |type|
    # only if a controller exists
    controller = "#{type.name.pluralize}Controller"
    next unless Object.const_defined?(controller)

    test "jsonld response for #{type}" do
      check_for_type(type)
    end
  end

  test 'response for not authorized jsonld request' do
    data_file = FactoryBot.create(:private_data_file)
    refute data_file.can_view?, 'DataFile expected to be not visible'
    url = polymorphic_url(data_file, format: :jsonld)
    get url
    assert_response :forbidden
    expected = { '@context' => 'https://schema.org',
                 '@type' => 'Error',
                 'name' => 'Forbidden',
                 'description' => "You may not view data_file:#{data_file.id}",
                 'statusCode' => 403 }
    assert_equal expected, JSON.parse(response.body)
  end

  private

  def check_for_type(type)
    object = FactoryBot.create("max_#{type.model_name.singular}".to_sym)
    login(object)
    assert object.can_view?, "#{type.name} expected to be visible"
    url = polymorphic_url(object, format: :jsonld)
    get url
    assert_response :success
    assert_equal 'application/ld+json; charset=utf-8', response.headers['Content-Type']
    actual = JSON.parse(response.body)
    object = object.latest_version if object.respond_to?(:latest_version)
    expected = JSON.parse(object.to_schema_ld)
    assert_equal expected, actual, "#{type.name} JSONLD expected to match"
  end

  def login(object)
    user = object.try(:contributor)&.user || @default_user
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end
