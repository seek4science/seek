require 'test_helper'
require 'integration/api_test_helper'

class PlaceholderCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'placeholder'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: @current_person)
    study = Factory(:study, investigation: investigation, contributor: @current_person)
    @assay = Factory(:assay, study: study, contributor: @current_person)
    @creator = Factory(:person)

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_placeholder.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    placeholder = Factory(:placeholder, policy: Factory(:public_policy), contributor: @current_person, creators: [@creator])
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: placeholder.id})
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    template_file = File.join(ApiTestHelper.template_dir, 'post_bad_placeholder.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    assert_no_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", params: @to_post
      #assert_response :unprocessable_entity
    end

    h = JSON.parse(response.body)

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
