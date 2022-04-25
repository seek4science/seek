module ReadApiTestSuite
  extend ActiveSupport::Testing::Declarative # Allows `test 'bla' do` definitions
  include ApiTestHelper

  def model
    raise NotImplementedError
  end

  ['min', 'max'].each do |m|
    test "can get #{m} resource" do
      res = Factory.create("#{m}_#{singular_name}".to_sym)
      res.reload
      user_login(res.contributor) if res.respond_to?(:contributor)
      template = load_get_template("get_#{m}_#{singular_name}.json.erb", res)
      api_get_test(template, res)
    end
  end

  test 'unauthorized user cannot get resource' do
    res = private_resource
    if res.respond_to?(:policy)
      user_login(Factory(:person))
      get member_url(res), as: :json
      assert_response :forbidden
      validate_json response.body, '#/definitions/errors'
    end
  end

  test 'getting resource with non-existent ID should throw error' do
    get member_url(model.maximum(:id) + 100000), as: :json
    assert_response :not_found
    validate_json response.body, '#/definitions/errors'
  end
end
