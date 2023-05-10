module ReadApiTestSuite
  # Class that can be used with polymorphic_url to generate an URL to an item with a non-existent ID
  class MissingItem
    def initialize(klass)
      @klass = klass
    end

    def model_name
      @klass.model_name
    end

    def to_model
      self
    end

    def persisted?
      true
    end

    def to_param
      (@klass.maximum(:id) || 0) + 100
    end
  end

  extend ActiveSupport::Testing::Declarative # Allows `test 'bla' do` definitions
  include ApiTestHelper

  def skip_index_test?
    false
  end

  def index_response_fragment
    "#/components/schemas/indexResponse"
  end

  ['min', 'max'].each do |m|
    test "can get #{m} resource" do
      res = FactoryBot.create("#{m}_#{singular_name}".to_sym)
      res.reload
      user_login(res.contributor) if res.respond_to?(:contributor)
      template = load_get_template("get_#{m}_#{singular_name}.json.erb", res)
      api_get_test(template, res)
    end
  end

  test 'can get index' do
    skip if skip_index_test?
    FactoryBot.create("min_#{singular_name}".to_sym)
    FactoryBot.create("max_#{singular_name}".to_sym)
    get collection_url, as: :json

    if model == Sample
      assert_response :not_implemented
    else
      perform_jsonapi_checks
      validate_json response.body, index_response_fragment
    end
  end

  test 'unauthorized user cannot get resource' do
    skip unless model.respond_to?(:authorization_supported?) && model.authorization_supported?
    res = private_resource

    user_login(FactoryBot.create(:person))
    get member_url(res), as: :json
    assert_response :forbidden
    validate_json response.body, '#/components/schemas/forbiddenResponse'
  end

  test 'getting resource with non-existent ID should throw error' do
    get member_url(MissingItem.new(model)), as: :json
    assert_response :not_found
    validate_json response.body, '#/components/schemas/notFoundResponse'
  end

  test 'write show example' do
    skip unless write_examples?

    res = FactoryBot.create("max_#{singular_name}".to_sym)
    user_login(res.contributor) if res.respond_to?(:contributor)
    get member_url(res), as: :json
    assert_response :success

    write_examples(JSON.pretty_generate(JSON.parse(response.body)), "#{singular_name.camelize(:lower)}Response.json")
  end

  test 'write index example' do
    skip unless write_examples? && !skip_index_test?

    model.delete_all unless model == Person
    FactoryBot.create("min_#{singular_name}".to_sym)
    FactoryBot.create("max_#{singular_name}".to_sym)

    get collection_url, as: :json

    if response.code.to_i == 200
      write_examples(JSON.pretty_generate(JSON.parse(response.body)), "#{plural_name.camelize(:lower)}Response.json")
    else
      warn "Response code was #{response.code} for #{plural_name} index, ignoring"
    end
  end
end
