require 'test_helper'
require 'integration/api_test_helper'

class EventCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'event'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    @publication = Factory(:publication, contributor: @current_person)
    @presentation = Factory(:presentation, contributor: @current_person)
    @data_file = Factory(:data_file, contributor: @current_person)
    @creator = Factory(:person)

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_event.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    event = Factory(:event, policy: Factory(:public_policy), contributor: @current_person)
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: event.id})
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    template_file = File.join(ApiTestHelper.template_dir, 'post_bad_event.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    assert_no_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", params: @to_post
      # assert_response :unprocessable_entity
      # validate_json_against_fragment response.body, '#/definitions/errors'
    end

    h = JSON.parse(response.body)

    pp h
    errors = h["errors"]

    assert errors.any?
    assert_equal "can't be blank", fetch_errors(errors, '/data/relationships/projects')[0]['detail']
    assert_equal "can't be blank", fetch_errors(errors, '/data/attributes/title')[0]['detail']
    policy_errors = fetch_errors(errors, '/data/attributes/policy').map { |p| p['detail'] }
    assert_includes policy_errors, "permissions contributor can't be blank"
    assert_includes policy_errors, "permissions access_type can't be blank"
    refute fetch_errors(errors, '/data/attributes/description').any?
    refute fetch_errors(errors, '/data/attributes/potato').any?
  end
end
